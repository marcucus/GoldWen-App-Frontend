import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('user_consents')
export class UserConsent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column({ default: false })
  dataProcessing: boolean;

  @Column({ default: false, nullable: true })
  marketing?: boolean;

  @Column({ default: false, nullable: true })
  analytics?: boolean;

  @Column()
  consentedAt: Date;

  @Column({ nullable: true })
  revokedAt?: Date;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.consents, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}
