import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToOne,
  Index,
} from 'typeorm';
import { MatchStatus } from '../../common/enums';
import { User } from './user.entity';
import { Chat } from './chat.entity';

@Entity('matches')
export class Match {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  user1Id: string;

  @Column()
  @Index()
  user2Id: string;

  @Column({
    type: 'enum',
    enum: MatchStatus,
    default: MatchStatus.MATCHED,
  })
  status: MatchStatus;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  compatibilityScore: number;

  @Column({ nullable: true })
  matchedAt: Date;

  @Column({ nullable: true })
  expiredAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.matchesAsUser1, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user1Id' })
  user1: User;

  @ManyToOne(() => User, (user) => user.matchesAsUser2, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user2Id' })
  user2: User;

  @OneToOne(() => Chat, (chat) => chat.match, { cascade: true })
  chat: Chat;
}
