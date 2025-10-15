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
import { Profile } from './profile.entity';
import { Prompt } from './prompt.entity';

@Entity('prompt_answers')
export class PromptAnswer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  profileId: string;

  @Column()
  @Index()
  promptId: string;

  @Column()
  answer: string;

  @Column()
  order: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => Profile, (profile) => profile.promptAnswers, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  profile: Profile;

  @ManyToOne(() => Prompt, (prompt) => prompt.answers, { onDelete: 'CASCADE' })
  @JoinColumn()
  prompt: Prompt;
}
