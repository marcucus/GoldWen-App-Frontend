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
import { User } from './user.entity';

export enum Platform {
  IOS = 'ios',
  ANDROID = 'android',
}

@Entity('push_tokens')
@Index(['token'], { unique: true })
@Index(['userId', 'platform'])
export class PushToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  userId: string;

  @Column()
  token: string;

  @Column({
    type: 'enum',
    enum: Platform,
  })
  platform: Platform;

  @Column({ nullable: true })
  appVersion?: string;

  @Column({ nullable: true })
  deviceId?: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  lastUsedAt?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.pushTokens, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
