# 🚀 AWS DataSync Cross-Account Automation Dashboard

A full-stack dashboard built using **React** (frontend), **Flask** (backend), and **Terraform** (infra-as-code) to automate AWS **DataSync** setup across two accounts for seamless S3-to-S3 transfers.

---

## 📸 Features

- 🔧 **Automated DataSync Setup**: IAM roles, bucket policies, locations, and task.
- 🎛️ **Dashboard UI**: Easy-to-use React frontend for triggering actions.
- 🧠 **Backend Logic**: Flask-based API that generates `.tfvars`, triggers `terraform apply` & `destroy`.
- 🧹 **Clean Teardown**: Automatically empties destination bucket and destroys infra.
- 🟢 **One-click DataSync Execution**: (Optional enhancement) Trigger task directly from the UI.

---

## 🗂️ Folder Structure

```
.
├── mydashboard/             # React frontend (build inside here)
├── templates/               # Optional Flask templates
├── server.py                # Flask backend
├── generated/               # Dynamically generated tfvars files
├── terraform/
│   ├── iam/                 # IAM roles and trust policies
│   ├── source-account/      # Bucket policy on source bucket
│   └── destination-account/ # DataSync locations & task
└── README.md
```

---

## 🔧 Prerequisites

- AWS CLI configured with:
  - `AccountA` → Source account
  - `AccountB` → Destination account
- Terraform ≥ v1.3+
- Python ≥ 3.8 and `virtualenv`
- Node.js (for React build)

---

## 🚀 Getting Started

### 1️⃣ Clone and Setup

```bash
git clone https://github.com/your-repo/datasync-dashboard.git
cd datasync-dashboard
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2️⃣ React Build (Frontend)

```bash
cd mydashboard
npm install
npm run build
```

### 3️⃣ Run Flask Server

```bash
python server.py
```

App will be live at: `http://localhost:5000`

---

## 🖥️ Dashboard Usage

### ✅ Create Configuration

- Input:
  - Source & destination bucket names
  - AWS Account IDs
  - IAM role names (optional, defaults used)
  - Region

- Action:
  - Creates IAM roles and policies
  - Applies source bucket policy
  - Configures DataSync locations and task

### ❌ Destroy Configuration

- Empties destination bucket (if exists)
- Destroys Terraform infra in reverse order

### ▶️ Start DataSync Task (Optional)

- Triggers the actual data transfer using boto3

---

## 🛠️ Backend Logic Highlights

- `run_terraform_commands()` → Runs init + apply
- `run_terraform_destroy()` → Runs destroy without init
- Uses `subprocess` to shell Terraform with generated `.tfvars`
- Uses `boto3` to empty destination S3 bucket before destroy

---

## 🔒 Security Note

Ensure your IAM roles follow **least privilege** and trust policies are scoped only to the DataSync service and specific accounts.

---

## ✅ Example Bucket Policy (Source)

```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::<DESTINATION_ACCOUNT_ID>:role/DataSyncDestinationRole"
  },
  "Action": [
    "s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"
  ],
  "Resource": [
    "arn:aws:s3:::your-source-bucket",
    "arn:aws:s3:::your-source-bucket/*"
  ]
}
```

---

## 🙌 Credits

Built by **Sarthak Bansal**  
DevOps Automation Enthusiast 🚀

---

## 📃 License

 Use this freely and modify as needed.