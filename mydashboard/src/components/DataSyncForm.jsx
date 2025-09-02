import React, { useState } from "react";
import axios from "axios";
import "./DataSyncForm.css";
import "react-toastify/dist/ReactToastify.css";
import { toast } from "react-toastify";

function DataSyncForm() {
  const [formData, setFormData] = useState({
    source_bucket: "",
    destination_bucket: "",
    source_account_id: "",
    destination_account_id: "",
    source_role_name: "",
    destination_role_name: "",
    source_region: "ap-south-1", // ✅ added
    destination_region: "ap-south-1", // ✅ added
  });

  const [loading, setLoading] = useState(false);
  const [output, setOutput] = useState("");

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    toast.info("Starting Terraform apply...");
    setLoading(true);
    setOutput("");

    try {
      const res = await axios.post(
        "http://localhost:5000/run-datasync",
        formData
      );
      setOutput(res.data.output);
      toast.success("Terraform executed successfully 🚀");
    } catch (err) {
      setOutput(err.response?.data?.output || "Unknown error");
      toast.error("Terraform failed ❌");
    } finally {
      setLoading(false);
    }
  };

  const handleDestroy = async () => {
    toast.warn("Starting Terraform destroy...");
    setLoading(true);
    setOutput("");

    try {
      const res = await axios.post(
        "http://localhost:5000/destroy-datasync",
        formData
      );
      setOutput(res.data.output);
      toast.success("Terraform destroyed successfully 🧨");
    } catch (err) {
      setOutput(err.response?.data?.output || "Unknown error");
      toast.error("Destroy failed ❌");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="form-page">
      <div className="form-wrapper">
        {/* <img src="https://www.appsquadz.com/img/stiklogo.png" alt="" /> */}
        <form className="form-container" onSubmit={handleSubmit}>
          <h2>Configure DataSync Automation</h2>

          <input
            name="source_bucket"
            value={formData.source_bucket}
            onChange={handleChange}
            placeholder="Source Bucket Name"
          />
          <input
            name="destination_bucket"
            value={formData.destination_bucket}
            onChange={handleChange}
            placeholder="Destination Bucket Name"
          />
          <input
            name="source_account_id"
            value={formData.source_account_id}
            onChange={handleChange}
            placeholder="Source Account ID"
          />
          <input
            name="destination_account_id"
            value={formData.destination_account_id}
            onChange={handleChange}
            placeholder="Destination Account ID"
          />

          <input
            name="source_role_name"
            value={formData.source_role_name}
            onChange={handleChange}
            placeholder="Source Role Name"
          />
          <input
            name="destination_role_name"
            value={formData.destination_role_name}
            onChange={handleChange}
            placeholder="Destination Role Name"
          />

          {/* SOURCE ACCOUNT REGION */}
          <select
            name="source_region"
            value={formData.source_region}
            onChange={handleChange}
            className="input"
          >
            <option value="us-east-1">US East (N. Virginia)</option>
            <option value="us-west-2">US West (Oregon)</option>
            <option value="eu-west-1">EU (Ireland)</option>
            <option value="ap-south-1">Asia Pacific (Mumbai)</option>
          </select>

          {/* DESTINATION ACCOUNT REGION */}
          <select
            name="destination_region"
            value={formData.destination_region}
            onChange={handleChange}
            className="input"
          >
            <option value="us-east-1">US East (N. Virginia)</option>
            <option value="us-west-2">US West (Oregon)</option>
            <option value="eu-west-1">EU (Ireland)</option>
            <option value="ap-south-1">Asia Pacific (Mumbai)</option>
          </select>

          <button type="submit" disabled={loading}>
            {loading ? (
              <span className="spinner"></span>
            ) : (
              "Generate Configuration"
            )}
          </button>

          <button
            type="button"
            className="destroy-btn"
            onClick={handleDestroy}
            disabled={loading}
          >
            Destroy Configuration
          </button>

          {/* ✅ Output appears below form, not replacing it */}
          <div className="output-container">
            {output && (
              <>
                <h3>Terraform Output:</h3>
                <pre>{output}</pre>
              </>
            )}
          </div>
        </form>
      </div>
    </div>
  );
}

export default DataSyncForm;
