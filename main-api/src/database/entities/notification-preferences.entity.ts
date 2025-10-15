import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';

@Entity('notification_preferences')
export class NotificationPreferences {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index({ unique: true })
  userId: string;

  @Column({ default: true })
  dailySelection: boolean;

  @Column({ default: true })
  newMatches: boolean;

  @Column({ default: true })
  newMessages: boolean;

  @Column({ default: true })
  chatExpiring: boolean;

  @Column({ default: true })
  subscriptionUpdates: boolean;

  @Column({ default: false })
  marketingEmails: boolean;

  @Column({ default: true })
  pushNotifications: boolean;

  @Column({ default: true })
  emailNotifications: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToOne(() => User, (user) => user.notificationPreferences, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  user: User;
}
