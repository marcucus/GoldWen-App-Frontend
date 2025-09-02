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
import { PersonalityQuestion } from './personality-question.entity';

@Entity('personality_answers')
export class PersonalityAnswer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  userId: string;

  @Column()
  @Index()
  questionId: string;

  @Column({ type: 'text', nullable: true })
  textAnswer: string;

  @Column({ type: 'int', nullable: true })
  numericAnswer: number;

  @Column({ type: 'boolean', nullable: true })
  booleanAnswer: boolean;

  @Column({ type: 'text', array: true, nullable: true })
  multipleChoiceAnswer: string[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.personalityAnswers, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  user: User;

  @ManyToOne(() => PersonalityQuestion, (question) => question.answers, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  question: PersonalityQuestion;
}
