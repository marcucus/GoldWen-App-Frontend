import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';
import { DailySelection } from './daily-selection.entity';

export enum ChoiceType {
  LIKE = 'like',
  PASS = 'pass',
}

@Entity('user_choices')
@Index(['userId', 'targetUserId', 'createdAt'])
@Index(['dailySelectionId'])
export class UserChoice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  userId: string;

  @Column()
  @Index()
  targetUserId: string;

  @Column({ nullable: true })
  dailySelectionId: string;

  @Column({
    type: 'enum',
    enum: ChoiceType,
  })
  choiceType: ChoiceType;

  @CreateDateColumn()
  createdAt: Date;

  // Relations
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'targetUserId' })
  targetUser: User;

  @ManyToOne(() => DailySelection, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'dailySelectionId' })
  dailySelection: DailySelection;
}
