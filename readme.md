# Synco ![Development](https://github.com/ioquatix/synco/workflows/Development/badge.svg)

Synco is a tool for scripted synchronization and backups. It provides a custom Ruby domain specific language (DSL) for describing backup and synchronization tasks involving one more more system and disk. It is designed to provide flexibility while reducing the complexity multi-server backups.

  - Single and multi-server data synchronization.
  - Incremental backups both locally and remotely.
  - Backup staging and coordination.
  - Backup verification using [Fingerprint](https://github.com/ioquatix/fingerprint).
  - Data backup redundancy controlled via DNS.

[![Development Status](https://github.com/ioquatix/synco/workflows/Test/badge.svg)](https://github.com/ioquatix/synco/actions?workflow=Test)

## Usage

Please see the [project documentation](https://ioquatix.github.io/synco/) for more details.

  - [Getting Started](https://ioquatix.github.io/synco/guides/getting-started/index) - This guide gives an overview of Synco, how to install it how to use it to backup and replicate data.

  - [Backup Policy](https://ioquatix.github.io/synco/guides/backup-policy/index) - This guide provides an overview of a Digital Information Backup Policy, including the main concerns affecting data retention and backup, the specific details that need to be considered, and the hardware and software solutions available to match your exact requirements.

  - [Backup Script](https://ioquatix.github.io/synco/guides/backup-script/index) - This guide explains how to create a backup script and the various options available to you.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
