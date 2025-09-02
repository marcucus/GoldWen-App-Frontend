import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { ChatStatus } from '../../common/enums';
import { Match } from './match.entity';
import { Message } from './message.entity';

@Entity('chats')
export class Chat {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  matchId: string;

  @Column({
    type: 'enum',
    enum: ChatStatus,
    default: ChatStatus.ACTIVE,
  })
  status: ChatStatus;

  @Column()
  expiresAt: Date;

  @Column({ nullable: true })
  lastMessageAt: Date;

  @Column({ type: 'int', default: 0 })
  messageCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToOne(() => Match, (match) => match.chat, { onDelete: 'CASCADE' })
  @JoinColumn()
  match: Match;

  @OneToMany(() => Message, (message) => message.chat, { cascade: true })
  messages: Message[];

  // Helper methods
  get isExpired(): boolean {
    return new Date() > this.expiresAt;
  }

  get timeRemaining(): number {
    const now = new Date().getTime();
    const expires = this.expiresAt.getTime();
    return Math.max(0, expires - now);
  }
}
