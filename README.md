# 🚀 AWS Terraform Infrastructure Automation  

## Overview  
This project automates the provisioning and management of AWS cloud infrastructure using **Terraform**. It deploys **EC2, RDS, ALB, S3, IAM, and VPC** resources, ensuring a secure, scalable, and efficient cloud environment. Additionally, it integrates **GitHub Actions** for CI/CD automation, enforcing **Infrastructure as Code (IaC)** best practices.  

## Features  
**Infrastructure as Code (IaC)** – Automates AWS infrastructure deployment with Terraform  
**CI/CD Automation** – Uses GitHub Actions for validation and auto-deployment  
**Secure Architecture** –  
  - RDS in **private VPC subnets** for enhanced security  
  - **IAM roles** for controlled access  
  - **S3 encryption & versioning** for data integrity  
**Load Balancing & Networking** – Deploys an **Application Load Balancer (ALB)** for traffic distribution  
**Remote State Management** – Uses **S3 & DynamoDB** to manage Terraform state  

## Architecture Diagram  
![aws_architecture](https://github.com/user-attachments/assets/beaa28c6-0647-4cd4-86af-f578eebd472c)

## Technologies Used  
- **Infrastructure as Code:** Terraform  
- **Cloud Provider:** AWS (EC2, RDS, ALB, S3, IAM, VPC)  
- **CI/CD:** GitHub Actions  
- **Networking & Security:** Private VPC, IAM, Security Groups  
- **State Management:** S3 & DynamoDB for Terraform remote state  

## Prerequisites  
Before using this project, ensure you have:  
- **Terraform** installed ([Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))  
- **AWS CLI** configured with appropriate IAM permissions  
- **GitHub Secrets** set up for AWS credentials:  
  - `AWS_ACCESS_KEY_ID`  
  - `AWS_SECRET_ACCESS_KEY`  
  - `DB_USERNAME`  
  - `DB_PASSWORD`  

## Installation & Setup  

### 1. Clone the Repository  
```sh
git clone https://github.com/bt00000/AWS-Terraform-Infrastructure-Automation.git
cd AWS-Terraform-Infrastructure-Automation
```

### 2. Initialize Terraform  
```sh
terraform init
```

### 3. Preview Changes (Optional)
```sh
terraform plan  
```

### 4. Apply Changes
```sh
terraform apply -auto-approve  
```

### 5. Retrieve Load Balancer DNS (if applicable)  
```sh
terraform output load_balancer_dns  
```

Access the application using the provided DNS.

---

## GitHub Actions CI/CD  
This project includes a **GitHub Actions** workflow that automates Terraform validation and deployment.

### CI/CD Pipeline Steps  
1. **Terraform Format & Validation** - Ensures Terraform scripts follow best practices.  
2. **Terraform Plan** - Previews changes before applying.  
3. **Terraform Apply** - Deploys changes when merged into the `main` branch.  

### GitHub Secrets Used  
- `AWS_ACCESS_KEY_ID`  
- `AWS_SECRET_ACCESS_KEY`  
- `DB_USERNAME`  
- `DB_PASSWORD`  

---

## Security & Best Practices  
**IAM & Least Privilege** - Implements IAM roles for restricted access.  
**S3 Encryption & Versioning** - Ensures data integrity & security.  
**Private RDS Subnets** - Keeps databases isolated from public access.  
**Terraform State Locking** - Uses S3 & DynamoDB for secure remote state management.  

---

## Future Enhancements  
Add **CloudWatch Monitoring & Logging**  
Implement **Terraform Modules** for better organization  
Expand CI/CD to support automated rollback  

---

## Troubleshooting  

### Terraform Apply Fails  
- Ensure AWS credentials are correct.  
- Verify **Terraform remote state** in S3 is accessible.  

### RDS Connection Issues  
- Confirm EC2 instance **security group** allows inbound connections to RDS.  
- Ensure `DB_USERNAME` and `DB_PASSWORD` are correctly set in **GitHub Secrets**.  

---

## License  
This project is licensed under the **MIT License**.  

---

## Author  
Created by **Brennan Tong** - [GitHub](https://github.com/bt00000)  

---
