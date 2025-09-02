import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { PromptAnswer } from './prompt-answer.entity';

@Entity('prompts')
export class Prompt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  text: string;

  @Column()
  order: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  category: string;

  @Column({ nullable: true })
  placeholder: string;

  @Column({ type: 'int', default: 500 })
  maxLength: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToMany(() => PromptAnswer, (answer) => answer.prompt)
  answers: PromptAnswer[];
}
