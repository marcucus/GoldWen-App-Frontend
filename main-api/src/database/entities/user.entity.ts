import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  OneToMany,
  Index,
} from 'typeorm';
import { UserStatus, FontSize, UserRole } from '../../common/enums';
import { Profile } from './profile.entity';
import { PersonalityAnswer } from './personality-answer.entity';
import { DailySelection } from './daily-selection.entity';
import { Match } from './match.entity';
import { Message } from './message.entity';
import { Subscription } from './subscription.entity';
import { Notification } from './notification.entity';
import { NotificationPreferences } from './notification-preferences.entity';
import { Report } from './report.entity';
import { SupportTicket } from './support-ticket.entity';
import { PushToken } from './push-token.entity';
import { UserConsent } from './user-consent.entity';

@Entity('users')
@Index(['email'], { unique: true })
@Index(['socialId', 'socialProvider'], { unique: true })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true })
  passwordHash: string;

  @Column({ nullable: true })
  socialId?: string;

  @Column({ nullable: true })
  socialProvider?: string; // 'google' | 'apple'

  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.ACTIVE,
  })
  status?: UserStatus;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.USER,
  })
  role?: UserRole;

  @Column({ default: false })
  isEmailVerified?: boolean;

  @Column({ nullable: true })
  emailVerificationToken?: string;

  @Column({ nullable: true })
  resetPasswordToken?: string;

  @Column({ nullable: true })
  resetPasswordExpires?: Date;

  @Column({ default: false })
  isOnboardingCompleted?: boolean;

  @Column({ default: false })
  isProfileCompleted?: boolean;

  @Column({ nullable: true })
  lastLoginAt?: Date;

  @Column({ nullable: true })
  lastActiveAt?: Date;

  @Column({ nullable: true })
  fcmToken?: string;

  @Column({ default: true })
  notificationsEnabled?: boolean;

  // Accessibility Settings
  @Column({
    type: 'enum',
    enum: FontSize,
    default: FontSize.MEDIUM,
  })
  fontSize?: FontSize;

  @Column({ default: false })
  highContrast?: boolean;

  @Column({ default: false })
  reducedMotion?: boolean;

  @Column({ default: false })
  screenReader?: boolean;

  @CreateDateColumn()
  createdAt?: Date;

  @UpdateDateColumn()
  updatedAt?: Date;

  @Column({ nullable: true })
  googleId?: string;

  // Relations
  @OneToOne(() => Profile, (profile) => profile.user, { cascade: true })
  profile?: Profile;

  @OneToMany(() => PersonalityAnswer, (answer) => answer.user, {
    cascade: true,
  })
  personalityAnswers?: PersonalityAnswer[];

  @OneToMany(() => DailySelection, (selection) => selection.user)
  dailySelections: DailySelection[];

  @OneToMany(() => Match, (match) => match.user1)
  matchesAsUser1?: Match[];

  @OneToMany(() => Match, (match) => match.user2)
  matchesAsUser2?: Match[];

  @OneToMany(() => Message, (message) => message.sender)
  sentMessages?: Message[];

  @OneToMany(() => Subscription, (subscription) => subscription.user)
  subscriptions?: Subscription[];

  @OneToMany(() => Notification, (notification) => notification.user)
  notifications?: Notification[];

  @OneToOne(() => NotificationPreferences, (preferences) => preferences.user)
  notificationPreferences?: NotificationPreferences;

  @OneToMany(() => Report, (report) => report.reporter)
  reportsSubmitted?: Report[];

  @OneToMany(() => Report, (report) => report.reportedUser)
  reportsReceived?: Report[];

  @OneToMany(() => SupportTicket, (ticket) => ticket.user)
  supportTickets?: SupportTicket[];

  @OneToMany(() => PushToken, (pushToken) => pushToken.user, { cascade: true })
  pushTokens?: PushToken[];

  @OneToMany(() => UserConsent, (consent) => consent.user, { cascade: true })
  consents?: UserConsent[];
}
