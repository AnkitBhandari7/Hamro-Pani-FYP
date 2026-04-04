/*
  Warnings:

  - The values [ADMIN] on the enum `notifications_sender_role` will be removed. If these variants are still used in the database, this will fail.
  - The values [ADMIN] on the enum `notifications_sender_role` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterTable
ALTER TABLE `notifications` MODIFY `sender_role` ENUM('RESIDENT', 'VENDOR', 'WARD_ADMIN') NOT NULL;

-- AlterTable
ALTER TABLE `users` ADD COLUMN `language` ENUM('EN', 'NP') NOT NULL DEFAULT 'EN',
    MODIFY `role` ENUM('RESIDENT', 'VENDOR', 'WARD_ADMIN') NOT NULL DEFAULT 'RESIDENT';

-- CreateTable
CREATE TABLE `saved_locations` (
    `location_id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `label` VARCHAR(191) NOT NULL,
    `address` VARCHAR(191) NOT NULL,
    `is_default` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `saved_locations_user_id_idx`(`user_id`),
    PRIMARY KEY (`location_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `saved_locations` ADD CONSTRAINT `saved_locations_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;
