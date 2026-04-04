-- AlterTable
ALTER TABLE `vendors` ADD COLUMN `address` VARCHAR(191) NULL,
    ADD COLUMN `tanker_count` INTEGER NOT NULL DEFAULT 0;
