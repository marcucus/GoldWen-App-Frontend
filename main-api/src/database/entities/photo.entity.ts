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

@Entity('photos')
@Index(['order'])
export class Photo {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  profileId: string;

  @Column()
  url: string;

  @Column()
  filename: string;

  @Column()
  order: number;

  @Column({ default: false })
  isPrimary: boolean;

  @Column({ type: 'int', nullable: true })
  width: number;

  @Column({ type: 'int', nullable: true })
  height: number;

  @Column({ type: 'int', nullable: true })
  fileSize: number; // in bytes

  @Column({ nullable: true })
  mimeType: string;

  @Column({ default: false })
  isApproved: boolean;

  @Column({ nullable: true })
  rejectionReason: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => Profile, (profile) => profile.photos, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  profile: Profile;
}
