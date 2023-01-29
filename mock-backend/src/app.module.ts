import { Module } from '@nestjs/common';
import { AppService } from './app.service';
import { PostsModule } from './posts/posts.module';
import { CommentsModule } from './comments/comments.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [PostsModule, CommentsModule, UsersModule],
  controllers: [],
  providers: [AppService],
})
export class AppModule {}
