import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { ReportStatus, ReportType } from '../../common/enums';
import { User } from './user.entity';
import { Admin } from './admin.entity';
import { Message } from './message.entity';
import { Chat } from './chat.entity';

@Entity('reports')
export class Report {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  reporterId: string;

  @Column()
  @Index()
  reportedUserId: string;

  @Column({
    type: 'enum',
    enum: ReportType,
  })
  type: ReportType;

  @Column({
    type: 'enum',
    enum: ReportStatus,
    default: ReportStatus.PENDING,
  })
  status: ReportStatus;

  @Column()
  reason: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'text', nullable: true })
  evidence?: string; // URLs or file paths to evidence

  @Column({ nullable: true })
  messageId?: string; // Optional: specific message being reported

  @Column({ nullable: true })
  chatId?: string; // Optional: chat where incident occurred

  @Column({ nullable: true })
  reviewedById?: string;

  @Column({ nullable: true })
  reviewedAt: Date;

  @Column({ type: 'text', nullable: true })
  reviewNotes: string;

  @Column({ type: 'text', nullable: true })
  resolution: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.reportsSubmitted, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'reporterId' })
  reporter: User;

  @ManyToOne(() => User, (user) => user.reportsReceived, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'reportedUserId' })
  reportedUser: User;

  @ManyToOne(() => Admin)
  @JoinColumn({ name: 'reviewedById' })
  reviewedBy: Admin;

  @ManyToOne(() => Message, { nullable: true })
  @JoinColumn({ name: 'messageId' })
  message?: Message;

  @ManyToOne(() => Chat, { nullable: true })
  @JoinColumn({ name: 'chatId' })
  chat?: Chat;
}
