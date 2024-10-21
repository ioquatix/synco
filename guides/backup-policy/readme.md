# Backup Policy

This guide provides an overview of a Digital Information Backup Policy, including the main concerns affecting data retention and backup, the specific details that need to be considered, and the hardware and software solutions available to match your exact requirements.

## What is a backup policy?

For organisations that rely on computers, a Digital Information Backup Policy is *critical* to secure and reliable business operations. A backup policy dictates how *important data* and *systems* are managed to ensure that there is a tolerance for various forms of data loss. The main goal is to ensure that if an organisation suffers some kind of data loss, it can continue to function effectively with a minimal additional overhead during data recovery.

Consider an office without a sufficiently capable backup; What would happen if all the customer invoices were accidentally deleted? Would anyone know who had paid what? How about filling a tax return? If an offsite backup was performed, was it secure? Was it complete and correct? If someone stole the offsite backup would that be a serious breach of customer confidence?

From our experience, many people buy hardware and try to fit that around their requirements without thinking about exactly the kind of data retention challenges they are facing. In many ways, this is like "putting the carriage in front of the horse". If you don't structure your backup policy around your requirements, there is the potential for serious problems.

## Policy Overview

The policy overview is a set of specific areas that need to be broadly considered when developing a backup policy. They represent the main concerns affecting data retention and backup.

- Accidental or malicious deletion of critical data.
	- The ability to quickly and easily restore individual files and folders.
- Data that is corrupted or lost over a period of time.
	- The ability to detect corruption and verify the correctness of a backup.
	- The ability to recover data from a previous point in time.
- Storage hardware failure (partial or complete).
	- The ability to recover quickly and easily from a complete hardware failure.
	- The amount of manual work required to fix a hardware failure.
- Server and software failure (partial or complete).
	- The ability to quickly diagnose and fix software problems.
	- The ability to replace failed servers with a minimal downtime.
	- The ability to replace failed servers without affecting the integrity of the backup.
- Local or regional disaster (partial or complete loss of an entire office/facility).
	- The ability to have multiple backups in physically different locations outside of the disaster zone.
- Remote offices and branch offices.
	- The ability to manage backup requirements with minimal technical support (including both performing backups and restoring lost files).
- Resource usage (including hardware, power, time).
	- The ability to *efficiently* perform backup and restore operations within a reasonable length of time.
- Data security (both on-site and off-site).
	- The ability to move data (as required) between different locations safely and securely.
	- The ability to maintain company reputation and customer confidence.

A backup policy may also be part of a wider company management policy regarding data retention and document management. In this case, you may specifically want to refer to it as a Digital Information Backup Policy.

## Policy Details

With the above concerns in mind, a backup policy can be structured to deal with the major issues of day-to-day operations. In a typical backup system, there are many specific details that need to be considered.

- Data Backup Requirements:
	- Data Sources:
		- File Servers
		- Database Servers
		- Client Desktops
	- Data Volume:
		- Initial Storage Capacity
		- Incremental Storage Growth (i.e. how much additional storage is required per month?)
	- Data Security:
		- The appropriate use of encryption and access control technologies to protect sensitive data.
	- Backup Frequency:
	- Backup Monitoring:
		- Backup Manager (i.e. who is responsible for backups?).
		- Backup Logging (i.e. success/failure email notifications).
	- Auditing and Verification.
- Data Retention Requirements:
	- Maximum allowable time for data recovery.
	- Minimum data retention period.
- Offsite Storage Requirements:
	- Location and facility specifications.
	- Security of facility:
		- Authorised personnel.
		- Security logging (i.e. security cameras, door monitoring, guards).
	- Storage of backup data and associated hardware/media.
		- Environmental Controls (i.e. temperature and humidity).
		- Power Conditioning (i.e. UPS, generator).
	- Auditing and Verification.

One of the most critical parts of a working backup is auditing and verification of the backup data. If this is not done, then at the time when a backup is needed, the data may be corrupt or missing. It is like paying someone to build a house without actually ever checking that there is any house being built.
