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

@Entity('daily_selections')
export class DailySelection {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  userId: string;

  @Column({ type: 'date' })
  selectionDate: Date;

  @Column({ type: 'uuid', array: true })
  selectedProfileIds: string[];

  @Column({ type: 'uuid', array: true, default: '{}' })
  chosenProfileIds: string[];

  @Column({ type: 'int', default: 0 })
  choicesUsed: number;

  @Column({ type: 'int', default: 1 })
  maxChoicesAllowed: number;

  @Column({ default: false })
  isNotificationSent: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.dailySelections, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  user: User;
}
