-- ============================================================
-- WORDLY APP - Complete Supabase Database Setup
-- ============================================================
-- Run this entire script in Supabase SQL Editor (one time).
-- It creates all tables, indexes, RLS policies, triggers,
-- seed words, and seed achievements.
-- ============================================================

-- ============================================================
-- 1. PROFILES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  level INTEGER NOT NULL DEFAULT 1,
  total_xp INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_login_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- 2. WORDS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.words (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  english_word TEXT NOT NULL UNIQUE,
  russian_translation TEXT NOT NULL,
  example_sentence TEXT,
  difficulty_level SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
  category TEXT NOT NULL DEFAULT 'general',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_words_difficulty ON public.words (difficulty_level);
CREATE INDEX IF NOT EXISTS idx_words_category ON public.words (category);
CREATE INDEX IF NOT EXISTS idx_words_english ON public.words (english_word);

ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read words"
  ON public.words FOR SELECT
  USING (auth.role() = 'authenticated');


-- ============================================================
-- 3. USER_WORD_PROGRESS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_word_progress (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  word_id BIGINT NOT NULL REFERENCES public.words(id) ON DELETE CASCADE,
  ease_factor REAL NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 0,
  repetition_count INTEGER NOT NULL DEFAULT 0,
  next_review_date DATE NOT NULL DEFAULT CURRENT_DATE,
  last_review_date DATE,
  correct_count INTEGER NOT NULL DEFAULT 0,
  incorrect_count INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT uq_user_word UNIQUE (user_id, word_id)
);

CREATE INDEX IF NOT EXISTS idx_uwp_user_next_review
  ON public.user_word_progress (user_id, next_review_date);

ALTER TABLE public.user_word_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own progress"
  ON public.user_word_progress FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- 4. ACHIEVEMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL DEFAULT 'star',
  condition_type TEXT NOT NULL,
  condition_value INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read achievements"
  ON public.achievements FOR SELECT
  USING (auth.role() = 'authenticated');


-- ============================================================
-- 5. USER_ACHIEVEMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id BIGINT NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_user_achievement UNIQUE (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_ua_user ON public.user_achievements (user_id);

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own achievements"
  ON public.user_achievements FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- 6. DAILY_STATS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.daily_stats (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  words_learned INTEGER NOT NULL DEFAULT 0,
  words_reviewed INTEGER NOT NULL DEFAULT 0,
  correct_answers INTEGER NOT NULL DEFAULT 0,
  incorrect_answers INTEGER NOT NULL DEFAULT 0,
  xp_earned INTEGER NOT NULL DEFAULT 0,
  session_duration_seconds INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT uq_user_date UNIQUE (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_ds_user_date
  ON public.daily_stats (user_id, date DESC);

ALTER TABLE public.daily_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own daily stats"
  ON public.daily_stats FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- 7. SEED DATA: WORDS (100+ words across 5 categories)
-- ============================================================

-- Category: Animals
INSERT INTO public.words (english_word, russian_translation, example_sentence, difficulty_level, category) VALUES
('cat', 'кошка', 'The cat is sleeping on the sofa.', 1, 'animals'),
('dog', 'собака', 'The dog is playing in the park.', 1, 'animals'),
('bird', 'птица', 'A bird is singing in the tree.', 1, 'animals'),
('fish', 'рыба', 'The fish is swimming in the pond.', 1, 'animals'),
('horse', 'лошадь', 'The horse runs across the field.', 1, 'animals'),
('rabbit', 'кролик', 'The rabbit hopped into the garden.', 1, 'animals'),
('elephant', 'слон', 'An elephant has a long trunk.', 2, 'animals'),
('butterfly', 'бабочка', 'The butterfly landed on the flower.', 2, 'animals'),
('dolphin', 'дельфин', 'Dolphins are very intelligent animals.', 2, 'animals'),
('eagle', 'орёл', 'The eagle soared above the mountains.', 2, 'animals'),
('penguin', 'пингвин', 'Penguins live in cold climates.', 2, 'animals'),
('whale', 'кит', 'The blue whale is the largest animal.', 2, 'animals'),
('squirrel', 'белка', 'The squirrel gathered nuts for winter.', 2, 'animals'),
('crocodile', 'крокодил', 'The crocodile lay still in the river.', 3, 'animals'),
('chameleon', 'хамелеон', 'A chameleon can change its color.', 3, 'animals'),
('hedgehog', 'ёж', 'The hedgehog curled into a ball.', 3, 'animals'),
('flamingo', 'фламинго', 'Flamingos stand on one leg.', 3, 'animals'),
('cheetah', 'гепард', 'The cheetah is the fastest land animal.', 3, 'animals'),
('octopus', 'осьминог', 'An octopus has eight arms.', 3, 'animals'),
('parrot', 'попугай', 'The parrot can repeat words.', 2, 'animals');

-- Category: Food
INSERT INTO public.words (english_word, russian_translation, example_sentence, difficulty_level, category) VALUES
('bread', 'хлеб', 'I bought fresh bread from the bakery.', 1, 'food'),
('water', 'вода', 'Please give me a glass of water.', 1, 'food'),
('apple', 'яблоко', 'An apple a day keeps the doctor away.', 1, 'food'),
('cheese', 'сыр', 'This cheese tastes amazing.', 1, 'food'),
('milk', 'молоко', 'Children should drink milk every day.', 1, 'food'),
('egg', 'яйцо', 'I had scrambled eggs for breakfast.', 1, 'food'),
('chicken', 'курица', 'We had roasted chicken for dinner.', 1, 'food'),
('rice', 'рис', 'Rice is a staple food in many countries.', 1, 'food'),
('sugar', 'сахар', 'Too much sugar is bad for your health.', 1, 'food'),
('salt', 'соль', 'Add a pinch of salt to the soup.', 1, 'food'),
('pepper', 'перец', 'Black pepper adds flavor to the dish.', 2, 'food'),
('mushroom', 'гриб', 'I found a mushroom in the forest.', 2, 'food'),
('strawberry', 'клубника', 'Strawberries are my favorite fruit.', 2, 'food'),
('pineapple', 'ананас', 'Pineapple juice is very refreshing.', 2, 'food'),
('cucumber', 'огурец', 'Cucumber is used in many salads.', 2, 'food'),
('garlic', 'чеснок', 'Garlic gives a strong flavor to food.', 2, 'food'),
('cinnamon', 'корица', 'Cinnamon smells wonderful in baking.', 3, 'food'),
('avocado', 'авокадо', 'Avocado toast is a popular breakfast.', 2, 'food'),
('broccoli', 'брокколи', 'Broccoli is a healthy green vegetable.', 2, 'food'),
('grapefruit', 'грейпфрут', 'Grapefruit has a sour taste.', 3, 'food');

-- Category: Travel
INSERT INTO public.words (english_word, russian_translation, example_sentence, difficulty_level, category) VALUES
('airport', 'аэропорт', 'We arrived at the airport two hours early.', 2, 'travel'),
('hotel', 'отель', 'The hotel room had a beautiful view.', 1, 'travel'),
('ticket', 'билет', 'I bought a train ticket online.', 1, 'travel'),
('passport', 'паспорт', 'Don''t forget your passport when traveling abroad.', 2, 'travel'),
('luggage', 'багаж', 'My luggage was lost at the airport.', 2, 'travel'),
('tourist', 'турист', 'The city is full of tourists in summer.', 2, 'travel'),
('beach', 'пляж', 'We spent the whole day at the beach.', 1, 'travel'),
('mountain', 'гора', 'The view from the mountain top was stunning.', 1, 'travel'),
('museum', 'музей', 'The museum has an amazing art collection.', 2, 'travel'),
('bridge', 'мост', 'The old bridge crosses the river.', 2, 'travel'),
('destination', 'пункт назначения', 'Paris was our final destination.', 3, 'travel'),
('journey', 'путешествие', 'The journey took three days.', 2, 'travel'),
('adventure', 'приключение', 'Every trip is a new adventure.', 2, 'travel'),
('souvenir', 'сувенир', 'I bought a souvenir for my friend.', 2, 'travel'),
('departure', 'отправление', 'The departure time is 8 AM.', 3, 'travel'),
('accommodation', 'жильё', 'We found cheap accommodation near the center.', 3, 'travel'),
('itinerary', 'маршрут', 'Our itinerary includes five cities.', 4, 'travel'),
('excursion', 'экскурсия', 'We went on an excursion to the old town.', 3, 'travel'),
('reservation', 'бронирование', 'I made a reservation at the restaurant.', 3, 'travel'),
('currency', 'валюта', 'You need to exchange currency before traveling.', 3, 'travel');

-- Category: Technology
INSERT INTO public.words (english_word, russian_translation, example_sentence, difficulty_level, category) VALUES
('computer', 'компьютер', 'I use my computer for work every day.', 1, 'technology'),
('phone', 'телефон', 'My phone battery is almost dead.', 1, 'technology'),
('internet', 'интернет', 'The internet connection is very slow today.', 1, 'technology'),
('password', 'пароль', 'Choose a strong password for your account.', 2, 'technology'),
('screen', 'экран', 'The laptop screen is cracked.', 1, 'technology'),
('keyboard', 'клавиатура', 'This keyboard is very comfortable to type on.', 2, 'technology'),
('software', 'программное обеспечение', 'We need to update the software.', 3, 'technology'),
('database', 'база данных', 'All user data is stored in a database.', 3, 'technology'),
('network', 'сеть', 'The company network is down.', 2, 'technology'),
('website', 'веб-сайт', 'I built a website for my business.', 2, 'technology'),
('download', 'скачать', 'You can download the file from the link.', 2, 'technology'),
('upload', 'загрузить', 'Please upload your photo to the form.', 2, 'technology'),
('algorithm', 'алгоритм', 'The search algorithm finds results quickly.', 4, 'technology'),
('encryption', 'шифрование', 'Encryption protects sensitive data.', 4, 'technology'),
('artificial', 'искусственный', 'Artificial intelligence is changing the world.', 3, 'technology'),
('bandwidth', 'пропускная способность', 'We need more bandwidth for video calls.', 4, 'technology'),
('bluetooth', 'блютуз', 'Connect your headphones via Bluetooth.', 2, 'technology'),
('browser', 'браузер', 'Open the link in your browser.', 2, 'technology'),
('cloud', 'облако', 'We store our files in the cloud.', 2, 'technology'),
('server', 'сервер', 'The server went down for maintenance.', 3, 'technology');

-- Category: Emotions
INSERT INTO public.words (english_word, russian_translation, example_sentence, difficulty_level, category) VALUES
('happy', 'счастливый', 'I am very happy today.', 1, 'emotions'),
('sad', 'грустный', 'She looked sad after hearing the news.', 1, 'emotions'),
('angry', 'злой', 'He was angry about the delay.', 1, 'emotions'),
('afraid', 'испуганный', 'The child was afraid of the dark.', 1, 'emotions'),
('surprised', 'удивлённый', 'I was surprised by the gift.', 2, 'emotions'),
('excited', 'взволнованный', 'The kids are excited about the trip.', 2, 'emotions'),
('tired', 'уставший', 'I feel tired after a long day.', 1, 'emotions'),
('bored', 'скучающий', 'He was bored during the lecture.', 2, 'emotions'),
('proud', 'гордый', 'She is proud of her achievements.', 2, 'emotions'),
('jealous', 'ревнивый', 'Try not to be jealous of others.', 3, 'emotions'),
('grateful', 'благодарный', 'I am grateful for your help.', 2, 'emotions'),
('anxious', 'тревожный', 'She felt anxious before the exam.', 3, 'emotions'),
('confident', 'уверенный', 'He spoke in a confident voice.', 2, 'emotions'),
('lonely', 'одинокий', 'Living alone can make you feel lonely.', 2, 'emotions'),
('curious', 'любопытный', 'Children are naturally curious about the world.', 2, 'emotions'),
('disappointed', 'разочарованный', 'I was disappointed with the result.', 3, 'emotions'),
('embarrassed', 'смущённый', 'She felt embarrassed in front of everyone.', 3, 'emotions'),
('relieved', 'облегчённый', 'I was relieved to hear the good news.', 3, 'emotions'),
('frustrated', 'расстроенный', 'He was frustrated with the slow progress.', 3, 'emotions'),
('enthusiastic', 'восторженный', 'She is enthusiastic about learning new things.', 3, 'emotions');


-- ============================================================
-- 8. SEED DATA: ACHIEVEMENTS
-- ============================================================
INSERT INTO public.achievements (name, description, icon_name, condition_type, condition_value) VALUES
('First Step', 'Learn your first word', 'star', 'words_learned', 1),
('Word Explorer', 'Learn 10 words', 'book', 'words_learned', 10),
('Vocabulary Builder', 'Learn 50 words', 'book', 'words_learned', 50),
('Word Master', 'Learn 100 words', 'crown', 'words_learned', 100),
('On Fire', 'Reach a 3-day streak', 'fire', 'streak_days', 3),
('Week Warrior', 'Reach a 7-day streak', 'fire', 'streak_days', 7),
('Monthly Champion', 'Reach a 30-day streak', 'trophy', 'streak_days', 30),
('XP Hunter', 'Earn 500 total XP', 'lightning', 'total_xp', 500),
('XP Master', 'Earn 2000 total XP', 'lightning', 'total_xp', 2000),
('Perfect Score', 'Get all answers correct in a quiz', 'target', 'perfect_quiz', 1);
