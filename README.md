# S O C I A L # M E D I A

## App Flow

1. **User Authentication**:

   - Users can sign up or log in using their email and password.
   - Authentication is handled via Supabase's authentication service.

2. **Home Feed**:

   - After logging in, users are directed to the home feed.
   - The feed displays posts from all users, sorted by the most recent.

3. **Creating a Post**:

   - Users can create a new post by uploading an image and adding a caption.
   - The post is then stored in the database and appears on the home feed.

4. **User Profiles**:

   - Each user has a profile page displaying their posts and basic information.
   - Users can edit their profile details.

5. **Likes and Comments**:

   - Users can like and comment on posts.
   - The like count and comments are updated in real-time.

6. **Logout**:

   - Users can log out, which clears their session and redirects them to the login screen.

## Database Structure

The app uses Supabase as the backend. Below is the database schema:

1. **Users Table**:

   - `id`: Unique identifier for each user.
   - `email`: User's email address.
   - `username`: Chosen username.
   - `profile_picture`: URL to the user's profile picture.

2. **Posts Table**:

   - `id`: Unique identifier for each post.
   - `user_id`: Foreign key linking to the user who created the post.
   - `image_url`: URL of the uploaded image.
   - `caption`: Text caption for the post.
   - `created_at`: Timestamp of when the post was created.

3. **Likes Table**:

   - `id`: Unique identifier for each like.
   - `post_id`: Foreign key linking to the liked post.
   - `user_id`: Foreign key linking to the user who liked the post.

4. **Comments Table**:

   - `id`: Unique identifier for each comment.
   - `post_id`: Foreign key linking to the commented post.
   - `user_id`: Foreign key linking to the user who made the comment.
   - `content`: Text of the comment.
   - `created_at`: Timestamp of when the comment was created.

5. **Profiles Table**:

   - `id`: Unique identifier (same as `user_id` in the Users table).
   - `bio`: Short biography of the user.
   - `website`: URL to the user's website or social media.

## Technologies Used

- **Frontend**: Flutter
- **Backend**: Supabase
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth

## Setup Instructions

1. Clone the repository.
2. Set up a Supabase project and configure the API keys in the app.
3. Run `flutter pub get` to install dependencies.
4. Use `flutter run` to start the app.
