import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PersonalityQuestion } from '../../database/entities/personality-question.entity';
import { Prompt } from '../../database/entities/prompt.entity';
import { QuestionType } from '../../common/enums';

@Injectable()
export class DatabaseSeederService implements OnModuleInit {
  constructor(
    @InjectRepository(PersonalityQuestion)
    private personalityQuestionRepository: Repository<PersonalityQuestion>,
    @InjectRepository(Prompt)
    private promptRepository: Repository<Prompt>,
  ) {}

  async onModuleInit() {
    await this.seedPersonalityQuestions();
    await this.seedPrompts();
  }

  private async seedPersonalityQuestions() {
    const existingCount = await this.personalityQuestionRepository.count();
    if (existingCount > 0) {
      return; // Already seeded
    }

    // 10 personality questions as specified in the requirements
    const questions = [
      {
        question:
          "Quel type d'activité préférez-vous pour un premier rendez-vous ?",
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          'Un café dans un endroit tranquille',
          'Une activité sportive ou de plein air',
          'Un musée ou une exposition',
          'Un bar avec de la musique live',
          'Une promenade dans un parc',
        ],
        order: 1,
        isRequired: true,
        category: 'lifestyle',
      },
      {
        question: 'Comment gérez-vous les conflits dans une relation ?',
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          'Je préfère en parler immédiatement',
          "J'ai besoin de temps pour réfléchir avant d'en parler",
          "J'essaie de comprendre le point de vue de l'autre",
          'Je cherche des compromis',
          "J'évite généralement les confrontations",
        ],
        order: 2,
        isRequired: true,
        category: 'communication',
      },
      {
        question:
          'Sur une échelle de 1 à 10, à quel point êtes-vous spontané(e) ?',
        type: QuestionType.SCALE,
        minValue: 1,
        maxValue: 10,
        order: 3,
        isRequired: true,
        category: 'personality',
      },
      {
        question:
          'Quelle importance accordez-vous à la famille dans votre vie ?',
        type: QuestionType.SCALE,
        minValue: 1,
        maxValue: 10,
        order: 4,
        isRequired: true,
        category: 'values',
      },
      {
        question: 'Quel est votre style de communication préféré ?',
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          'Messages textes fréquents',
          'Appels téléphoniques',
          'Face à face uniquement',
          'Mélange de tout',
          'Peu de communication, qualité over quantité',
        ],
        order: 5,
        isRequired: true,
        category: 'communication',
      },
      {
        question: 'Comment envisagez-vous votre week-end idéal ?',
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          'Aventures et découvertes',
          'Détente à la maison',
          'Socialiser avec des amis',
          'Activités culturelles',
          'Sport et exercice',
        ],
        order: 6,
        isRequired: true,
        category: 'lifestyle',
      },
      {
        question: 'À quel point êtes-vous ambitieux(se) professionnellement ?',
        type: QuestionType.SCALE,
        minValue: 1,
        maxValue: 10,
        order: 7,
        isRequired: true,
        category: 'career',
      },
      {
        question: 'Quelle est votre approche face aux nouvelles expériences ?',
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          'Je suis toujours partant(e)',
          "J'ai besoin de temps pour m'adapter",
          'Ça dépend du contexte',
          'Je préfère mes routines',
          "J'aime explorer mais avec modération",
        ],
        order: 8,
        isRequired: true,
        category: 'personality',
      },
      {
        question: "Quel rôle joue l'humour dans vos relations ?",
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          "Essentiel, j'adore rire",
          'Important mais pas primordial',
          "J'apprécie l'humour intelligent",
          'Je suis plutôt sérieux(se)',
          "J'aime l'humour sarcastique",
        ],
        order: 9,
        isRequired: true,
        category: 'personality',
      },
      {
        question: 'Comment définiriez-vous vos valeurs principales ?',
        type: QuestionType.MULTIPLE_CHOICE,
        options: [
          'Honnêteté et authenticité',
          'Compassion et empathie',
          'Ambition et réussite',
          'Liberté et indépendance',
          'Stabilité et sécurité',
        ],
        order: 10,
        isRequired: true,
        category: 'values',
      },
    ];

    for (const questionData of questions) {
      const question = this.personalityQuestionRepository.create(questionData);
      await this.personalityQuestionRepository.save(question);
    }
  }

  private async seedPrompts() {
    const existingCount = await this.promptRepository.count();
    if (existingCount > 0) {
      return; // Already seeded
    }

    // Prompts for profile completion (users need to answer 3)
    const prompts = [
      {
        text: "Ma plus grande passion dans la vie, c'est...",
        order: 1,
        isActive: true,
        category: 'passion',
      },
      {
        text: "Ce qui me fait rire aux éclats, c'est...",
        order: 2,
        isActive: true,
        category: 'humor',
      },
      {
        text: 'Mon endroit préféré pour me détendre est...',
        order: 3,
        isActive: true,
        category: 'lifestyle',
      },
      {
        text: "Si je pouvais dîner avec n'importe qui, ce serait...",
        order: 4,
        isActive: true,
        category: 'aspiration',
      },
      {
        text: 'Ma devise de vie pourrait être...',
        order: 5,
        isActive: true,
        category: 'values',
      },
      {
        text: "Ce qui me rend unique, c'est...",
        order: 6,
        isActive: true,
        category: 'personality',
      },
      {
        text: "Mon talent caché, c'est...",
        order: 7,
        isActive: true,
        category: 'skills',
      },
      {
        text: "L'aventure la plus folle que j'aie vécue...",
        order: 8,
        isActive: true,
        category: 'experience',
      },
      {
        text: "Ce qui me motive chaque matin, c'est...",
        order: 9,
        isActive: true,
        category: 'motivation',
      },
      {
        text: "Si j'avais une machine à remonter le temps...",
        order: 10,
        isActive: true,
        category: 'dreams',
      },
    ];

    for (const promptData of prompts) {
      const prompt = this.promptRepository.create(promptData);
      await this.promptRepository.save(prompt);
    }
  }
}
