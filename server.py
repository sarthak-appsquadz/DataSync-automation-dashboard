from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import subprocess
import os
import time
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__, static_folder='mydashboard/build', static_url_path='/')
CORS(app)

def run_terraform_commands(directory, tfvars_file, timeout=300):
    try:
        abs_tfvars_path = os.path.abspath(tfvars_file)
        env = os.environ.copy()
        env["AWS_PROFILE"] = "AccountB" if "destination" in directory else "AccountA"
        if "iam" in directory:
            env["AWS_PROFILE"] = "AccountA"  # IAM for both, use AccountA for plan/apply

        print(f"\n▶ Running terraform init in {directory}...")
        init_proc = subprocess.run(["terraform", "init"], cwd=directory, capture_output=True, text=True, env=env)
        print("✅ Init stdout:\n", init_proc.stdout)
        if init_proc.returncode != 0:
            print("❌ Init stderr:\n", init_proc.stderr)
            return False, f"[INIT ERROR]\n{init_proc.stderr}"

        print(f"\n🟡 Starting terraform apply in {directory} with {abs_tfvars_path}...")
        start_time = time.time()
        apply_proc = subprocess.Popen(
            ["terraform", "apply", "-auto-approve", f"-var-file={abs_tfvars_path}", "-no-color"],
            cwd=directory,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env
        )

        stdout, stderr = "", ""
        while apply_proc.poll() is None:
            if time.time() - start_time > timeout:
                apply_proc.kill()
                return False, "[TIMEOUT ERROR] Terraform apply took too long and was terminated."
            out_line = apply_proc.stdout.readline()
            if out_line:
                print(out_line, end="")
                stdout += out_line

        out, err = apply_proc.communicate()
        stdout += out
        stderr += err

        if apply_proc.returncode != 0:
            print("❌ Apply stderr:\n", stderr)
            return False, f"[APPLY ERROR]\n{stderr}"

        print("✅ Terraform apply completed successfully.")
        return True, stdout

    except Exception as e:
        return False, f"[EXCEPTION] {str(e)}"


def empty_s3_bucket(bucket_name, profile):
    session = boto3.Session(profile_name=profile)
    s3 = session.resource("s3")
    bucket = s3.Bucket(bucket_name)
    try:
        print(f"🧹 Emptying bucket: {bucket_name} using profile {profile}")
        bucket.objects.all().delete()
        print(f"✅ Bucket {bucket_name} emptied successfully.")
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchBucket':
            print(f"⚠️ Bucket {bucket_name} does not exist, skipping.")
        else:
            print(f"❌ Failed to empty bucket {bucket_name}: {str(e)}")


def run_terraform_destroy(directory, var_file):
    try:
        abs_directory = os.path.abspath(directory)
        abs_var_file = os.path.abspath(var_file)

        print(f"🧨 Running terraform destroy in {abs_directory} with {abs_var_file}...")
        if not os.path.exists(abs_var_file):
            return False, f"[ERROR] Var file not found: {abs_var_file}"

        destroy_cmd = [
            "terraform", "destroy",
            "-auto-approve",
            f"-var-file={abs_var_file}",
            "-lock=false",
            "-no-color"
        ]

        process = subprocess.Popen(
            destroy_cmd,
            cwd=abs_directory,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        output = ""
        while process.poll() is None:
            output_line = process.stdout.readline()
            if output_line:
                print(output_line.strip(), flush=True)
                output += output_line

        remaining_output, _ = process.communicate()
        output += remaining_output

        if process.returncode != 0:
            print("❌ Terraform destroy failed.")
            return False, output

        print("✅ Terraform destroy completed successfully.")
        return True, output

    except subprocess.TimeoutExpired:
        return False, "[ERROR] Terraform destroy timed out."
    except Exception as e:
        return False, f"[EXCEPTION] {str(e)}"


@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def serve_react(path):
    if path != "" and os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    else:
        return send_from_directory(app.static_folder, "index.html")


@app.route("/run-datasync", methods=["POST"])
def run_datasync():
    data = request.get_json()
    print("✅ Received request to /run-datasync")
    print("🧠 Form data received:", data)

    try:
        source_bucket = data["source_bucket"]
        destination_bucket = data["destination_bucket"]
        source_account_id = data["source_account_id"]
        destination_account_id = data["destination_account_id"]
        # region = data["region"]
        source_region = data["source_region"]
        destination_region = data["destination_region"]


        os.makedirs("generated", exist_ok=True)

        # Write tfvars for IAM
        iam_tfvars = "generated/iam.tfvars"
        with open(iam_tfvars, "w") as f:
            f.write(f'source_profile = "AccountA"\n')
            f.write(f'destination_profile = "AccountB"\n')
            f.write(f'source_region = "{source_region}"\n')
            f.write(f'destination_region = "{destination_region}"\n')

            # f.write(f'source_region = "{region}"\n')
            # f.write(f'destination_region = "{region}"\n')
            f.write(f'source_bucket_name = "{source_bucket}"\n')
            f.write(f'destination_bucket_name = "{destination_bucket}"\n')
            f.write(f'source_role_name = "DataSyncSourceRole"\n')
            f.write(f'destination_role_name = "DataSyncDestinationRole"\n')
            f.write(f'destination_account_id = "{destination_account_id}"\n')

        # Step 1: Run Terraform for IAM
        print("🔐 Running Terraform for iam/...")
        success_iam, output_iam = run_terraform_commands("terraform/iam", iam_tfvars)
        if not success_iam:
            return jsonify({"output": "[IAM APPLY FAILED]\n" + output_iam}), 500

        # Step 2: Get IAM role ARNs from output
        def get_terraform_output(folder, output_name):
            result = subprocess.run(
                ["terraform", "output", "-raw", output_name],
                cwd=folder,
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                print(f"⚠️ Warning: Could not get output {output_name}")
                return ""
            return result.stdout.strip()

        source_role_arn = get_terraform_output("terraform/iam", "source_role_arn")
        destination_role_arn = get_terraform_output("terraform/iam", "destination_role_arn")

        # Step 3: Write source.tfvars
        source_tfvars = "generated/source.tfvars"
        with open(source_tfvars, "w") as f:
            f.write(f'source_bucket = "{source_bucket}"\n')
            f.write(f'destination_role_arn = "{destination_role_arn}"\n')
            f.write(f'profile = "AccountA"\n')
            # f.write(f'region = "{region}"\n')
            f.write(f'source_region = "{source_region}"\n')
            f.write(f'source_role_arn = "{source_role_arn}"\n')

        # Step 4: Write destination.tfvars
        dest_tfvars = "generated/destination.tfvars"
        with open(dest_tfvars, "w") as f:
            f.write(f'destination_bucket = "{destination_bucket}"\n')
            f.write(f'profile = "AccountB"\n')
            f.write(f'source_bucket = "{source_bucket}"\n')
            f.write(f'destination_account_id = "{destination_account_id}"\n')
            f.write(f'source_role_arn = "{source_role_arn}"\n')
            f.write(f'destination_role_arn = "{destination_role_arn}"\n')
            # f.write(f'region = "{region}"\n')
            f.write(f'destination_region = "{destination_region}"\n')
            f.write(f'source_region = "{source_region}"\n')


        # Step 5: Apply for source-account
        print("📦 Running Terraform for source-account...")
        success_src, output_src = run_terraform_commands("terraform/source-account", source_tfvars)
        if not success_src:
            return jsonify({"output": "[SOURCE APPLY FAILED]\n" + output_src}), 500

        # Step 6: Apply for destination-account
        print("📦 Running Terraform for destination-account...")
        success_dest, output_dest = run_terraform_commands("terraform/destination-account", dest_tfvars)
        if not success_dest:
            return jsonify({"output": "[DESTINATION APPLY FAILED]\n" + output_dest}), 500

        return jsonify({
            "output": "[IAM APPLY ✅]\n" + output_iam +
                      "\n\n[SOURCE APPLY ✅]\n" + output_src +
                      "\n\n[DESTINATION APPLY ✅]\n" + output_dest
        }), 200

    except Exception as e:
        return jsonify({"output": f"🔥 Exception occurred: {str(e)}"}), 500


@app.route("/destroy-datasync", methods=["POST"])
def destroy_datasync():
    data = request.get_json()
    print("🧨 Received request to /destroy-datasync")
    print("🧠 Destroy form data received:", data)

    try:
        source_bucket = data["source_bucket"]
        destination_bucket = data["destination_bucket"]
        source_account_id = data["source_account_id"]
        destination_account_id = data["destination_account_id"]
        destination_role_name = data["destination_role_name"]
        source_role_name = data["source_role_name"]
        # region = data["region"]
        source_region = data["source_region"]
        destination_region = data["destination_region"]


          # ✅ Now build the ARNs using the extracted values
        source_role_arn = f"arn:aws:iam::{source_account_id}:role/{source_role_name}"
        destination_role_arn = f"arn:aws:iam::{destination_account_id}:role/{destination_role_name}"

     

        os.makedirs("generated", exist_ok=True)

        source_tfvars = os.path.abspath("generated/source.tfvars")
        with open(source_tfvars, "w") as f:
            f.write(f'source_bucket = "{source_bucket}"\n')
            f.write(f'destination_role_arn = "{destination_role_arn}"\n')
            f.write(f'profile = "AccountA"\n')
            # f.write(f'region = "{region}"\n')
            f.write(f'region = "{source_region}"\n')
            f.write(f'source_role_arn = "{source_role_arn}"\n')

        dest_tfvars = os.path.abspath("generated/destination.tfvars")
        with open(dest_tfvars, "w") as f:
            f.write(f'destination_bucket = "{destination_bucket}"\n')
            f.write(f'profile = "AccountB"\n')
            f.write(f'source_bucket = "{source_bucket}"\n')
            f.write(f'destination_account_id = "{destination_account_id}"\n')
            f.write(f'source_role_arn = "{source_role_arn}"\n')
            f.write(f'destination_role_arn = "{destination_role_arn}"\n')
            # f.write(f'region = "{region}"\n')
            f.write(f'region = "{destination_region}"\n')


        empty_s3_bucket(destination_bucket, "AccountB")

        print("⚙️ Starting Terraform destroy for source-account...")
        success_src, output_src = run_terraform_destroy("terraform/source-account", source_tfvars)
        if not success_src:
            return jsonify({"output": output_src}), 500

        print("⚙️ Starting Terraform destroy for destination-account...")
        success_dest, output_dest = run_terraform_destroy("terraform/destination-account", dest_tfvars)
        if not success_dest:
            return jsonify({"output": output_dest}), 500

        return jsonify({"output": output_src + "\n\n" + output_dest}), 200

    except Exception as e:
        return jsonify({"output": f"🔥 Exception occurred: {str(e)}"}), 500


if __name__ == "__main__":
    app.run(debug=True)
