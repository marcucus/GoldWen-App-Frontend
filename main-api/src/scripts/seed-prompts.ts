import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { AdminService } from '../modules/admin/admin.service';
import { CreatePromptDto } from '../modules/admin/dto/prompt.dto';

async function seedPrompts() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const adminService = app.get(AdminService);

  console.log('Creating sample prompts...');

  const prompts: CreatePromptDto[] = [
    {
      text: 'What makes you laugh the most?',
      order: 1,
      isRequired: true,
      category: 'personality',
      placeholder: 'Share what brings joy to your life...',
      maxLength: 300,
    },
    {
      text: 'Describe your perfect weekend.',
      order: 2,
      isRequired: true,
      category: 'lifestyle',
      placeholder: 'Tell us about your ideal way to relax...',
      maxLength: 300,
    },
    {
      text: 'What are you most passionate about?',
      order: 3,
      isRequired: true,
      category: 'interests',
      placeholder: 'What drives you in life?',
      maxLength: 300,
    },
    {
      text: 'What is your hidden talent?',
      order: 4,
      isRequired: false,
      category: 'fun',
      placeholder: 'Something unique about you...',
      maxLength: 200,
    },
    {
      text: 'What book or movie changed your perspective?',
      order: 5,
      isRequired: false,
      category: 'culture',
      placeholder: 'Share something that influenced your worldview...',
      maxLength: 400,
    },
  ];

  try {
    for (const promptData of prompts) {
      const prompt = await adminService.createPrompt(promptData);
      console.log(
        `✅ Created prompt: "${prompt.text}" (Required: ${prompt.isRequired})`,
      );
    }

    console.log('\n📊 Summary:');
    console.log(
      `- ${prompts.filter((p) => p.isRequired).length} required prompts`,
    );
    console.log(
      `- ${prompts.filter((p) => !p.isRequired).length} optional prompts`,
    );
    console.log(`- Total: ${prompts.length} prompts`);

    const allPrompts = await adminService.getPrompts();
    console.log(`\n📋 All prompts in system: ${allPrompts.length}`);
  } catch (error) {
    console.error('❌ Error creating prompts:', error);
  } finally {
    await app.close();
  }
}

// Run the seed script
if (require.main === module) {
  seedPrompts()
    .then(() => {
      console.log('✨ Prompt seeding completed!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Prompt seeding failed:', error);
      process.exit(1);
    });
}
