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
import { Gender } from '../../common/enums';
import { User } from './user.entity';
import { Photo } from './photo.entity';
import { PromptAnswer } from './prompt-answer.entity';

@Entity('profiles')
export class Profile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index()
  userId: string;

  @Column()
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({ nullable: true })
  birthDate: Date;

  @Column({
    type: 'enum',
    enum: Gender,
    nullable: true,
  })
  gender: Gender;

  @Column({
    type: 'enum',
    enum: Gender,
    array: true,
    nullable: true,
  })
  interestedInGenders: Gender[];

  @Column({ nullable: true })
  bio: string;

  @Column({ nullable: true })
  jobTitle: string;

  @Column({ nullable: true })
  company: string;

  @Column({ nullable: true })
  education: string;

  @Column({ nullable: true })
  location: string;

  @Column('decimal', { precision: 10, scale: 8, nullable: true })
  latitude: number;

  @Column('decimal', { precision: 11, scale: 8, nullable: true })
  longitude: number;

  @Column({ type: 'int', nullable: true })
  maxDistance: number; // in kilometers

  @Column({ type: 'int', nullable: true })
  minAge: number;

  @Column({ type: 'int', nullable: true })
  maxAge: number;

  @Column({ type: 'text', array: true, default: '{}' })
  interests: string[];

  @Column({ type: 'text', array: true, default: '{}' })
  languages: string[];

  @Column({ nullable: true })
  height: number; // in cm

  @Column({ default: false })
  isVerified: boolean;

  @Column({ default: true })
  isVisible: boolean;

  @Column({ default: true })
  showAge: boolean;

  @Column({ default: true })
  showDistance: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToOne(() => User, (user) => user.profile)
  @JoinColumn()
  user: User;

  @OneToMany(() => Photo, (photo) => photo.profile, { cascade: true })
  photos: Photo[];

  @OneToMany(() => PromptAnswer, (answer) => answer.profile, { cascade: true })
  promptAnswers: PromptAnswer[];

  // Computed properties
  get age(): number | null {
    if (!this.birthDate) {
      return null;
    }
    
    const today = new Date();
    const birthDate = new Date(this.birthDate);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();

    if (
      monthDiff < 0 ||
      (monthDiff === 0 && today.getDate() < birthDate.getDate())
    ) {
      age--;
    }

    return age;
  }
}
