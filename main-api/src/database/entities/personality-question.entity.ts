import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { QuestionType } from '../../common/enums';
import { PersonalityAnswer } from './personality-answer.entity';

@Entity('personality_questions')
export class PersonalityQuestion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  question: string;

  @Column({
    type: 'enum',
    enum: QuestionType,
  })
  type: QuestionType;

  @Column({ type: 'json', nullable: true })
  options: string[]; // For multiple choice questions

  @Column({ type: 'int', nullable: true })
  minValue: number; // For scale questions

  @Column({ type: 'int', nullable: true })
  maxValue: number; // For scale questions

  @Column()
  order: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isRequired: boolean;

  @Column({ nullable: true })
  category: string;

  @Column({ nullable: true })
  description: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToMany(() => PersonalityAnswer, (answer) => answer.question)
  answers: PersonalityAnswer[];
}
