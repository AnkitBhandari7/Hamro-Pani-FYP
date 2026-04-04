-- AlterTable
ALTER TABLE `bookings` MODIFY `status` ENUM('PENDING', 'CONFIRMED', 'DELIVERED', 'CANCELLED', 'COMPLETED') NOT NULL DEFAULT 'PENDING';

-- AlterTable
ALTER TABLE `status_history` MODIFY `old_status` ENUM('PENDING', 'CONFIRMED', 'DELIVERED', 'CANCELLED', 'COMPLETED') NOT NULL,
    MODIFY `new_status` ENUM('PENDING', 'CONFIRMED', 'DELIVERED', 'CANCELLED', 'COMPLETED') NOT NULL;

-- AlterTable
ALTER TABLE `vendors` ADD COLUMN `rating_average` DOUBLE NOT NULL DEFAULT 0,
    ADD COLUMN `rating_count` INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE `vendor_ratings` (
    `vendor_rating_id` INTEGER NOT NULL AUTO_INCREMENT,
    `booking_id` INTEGER NOT NULL,
    `vendor_id` INTEGER NOT NULL,
    `resident_id` INTEGER NOT NULL,
    `rating` INTEGER NOT NULL,
    `comment` VARCHAR(191) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `vendor_ratings_booking_id_key`(`booking_id`),
    INDEX `vendor_ratings_vendor_id_idx`(`vendor_id`),
    INDEX `vendor_ratings_resident_id_idx`(`resident_id`),
    PRIMARY KEY (`vendor_rating_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `vendor_ratings` ADD CONSTRAINT `vendor_ratings_booking_id_fkey` FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vendor_ratings` ADD CONSTRAINT `vendor_ratings_vendor_id_fkey` FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`vendor_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vendor_ratings` ADD CONSTRAINT `vendor_ratings_resident_id_fkey` FOREIGN KEY (`resident_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;
