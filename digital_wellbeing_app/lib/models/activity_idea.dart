/// Full catalogue of built-in self-improvement activities.
/// Loaded directly from memory — no database required.
const List<ActivityIdea> kAllActivities = [
  ActivityIdea(
    title: 'Box Breathing',
    description:
        'Inhale for 4 s, hold for 4 s, exhale for 4 s, hold for 4 s. Repeat 4 rounds to calm your nervous system.',
    emoji: '🫁',
    category: 'Mindfulness',
    durationMinutes: 5,
    stepsRaw:
        'Sit upright in a chair or on the floor with your spine straight\n'
        'Exhale fully through your mouth to empty your lungs\n'
        'Inhale slowly through your nose for exactly 4 counts\n'
        'Hold your breath for 4 counts — keep your chest still\n'
        'Exhale smoothly through your nose or mouth for 4 counts\n'
        'Hold empty for 4 counts before the next inhale\n'
        'Repeat the full cycle at least 4 times\n'
        'After the last round, breathe normally and notice how you feel',
    benefitsRaw:
        'Activates the parasympathetic nervous system, reducing stress hormones instantly\n'
        'Lowers heart rate and blood pressure within minutes\n'
        'Improves focus and mental clarity by increasing oxygen to the brain\n'
        'Reduces anxiety and panic — used by Navy SEALs before high-pressure situations\n'
        'Builds long-term emotional regulation and resilience with daily practice',
  ),
  ActivityIdea(
    title: 'Cold Shower',
    description:
        'Finish your shower with 60 seconds of cold water to boost alertness, mood and circulation.',
    emoji: '🚿',
    category: 'Fitness',
    durationMinutes: 10,
    stepsRaw:
        'Take your normal warm shower first\n'
        'Before turning off, slowly reduce the temperature to cool\n'
        'Then turn it fully cold — breathe slowly and do not fight it\n'
        'Direct the cold water to your head, neck, chest and back\n'
        'Stay under for at least 30–60 seconds while breathing calmly\n'
        'Focus on your breath, not the discomfort — it fades in 10–15 seconds\n'
        'Turn off the water and towel dry vigorously to warm up',
    benefitsRaw:
        'Triggers release of norepinephrine — a potent mood and focus booster\n'
        'Increases alertness and energy for up to 2–3 hours afterward\n'
        'Improves blood circulation and lymphatic drainage\n'
        'Builds mental toughness and willpower by doing something uncomfortable intentionally\n'
        'Reduces muscle soreness and speeds up recovery after exercise\n'
        'Linked to reduced symptoms of depression in clinical studies',
  ),
  ActivityIdea(
    title: 'Meditate',
    description:
        'Sit comfortably, close your eyes and focus only on your breath for 10 minutes.',
    emoji: '🧘',
    category: 'Mindfulness',
    durationMinutes: 10,
    stepsRaw:
        'Find a quiet spot — sit on a chair, cushion or floor with your back straight\n'
        'Set a gentle timer for 10 minutes so you are not watching the clock\n'
        'Close your eyes and let your hands rest comfortably on your knees\n'
        'Take 3 deep breaths to settle in, then let your breathing become natural\n'
        'Place your full attention on the sensation of breath at your nostrils or belly\n'
        'When your mind wanders (it will), gently notice it and return to the breath — no judgment\n'
        'Each return to the breath is a mental rep — the practice is in the returning\n'
        'When the timer sounds, open your eyes slowly and sit still for 30 seconds',
    benefitsRaw:
        'Reduces cortisol (stress hormone) levels measurably after just 8 weeks\n'
        'Thickens the prefrontal cortex — the part of the brain responsible for decision-making\n'
        'Improves attention span and ability to focus deeply\n'
        'Reduces rumination and negative self-talk over time\n'
        'Improves sleep quality, especially when practiced in the evening\n'
        'Lowers anxiety and symptoms of depression, comparable to medication in some studies',
  ),
  ActivityIdea(
    title: 'Walk the Hallway',
    description:
        'Take a brisk walk around the passage, lobby or outside to stretch your legs and clear your mind.',
    emoji: '🚶',
    category: 'Fitness',
    durationMinutes: 10,
    stepsRaw:
        'Stand up from where you have been sitting and take a few slow breaths\n'
        'Start walking at a pace slightly faster than casual\n'
        'Let your arms swing naturally to engage your upper body\n'
        'Keep your posture upright — head up, shoulders back, core lightly engaged\n'
        'Walk continuously for at least 8–10 minutes without stopping to check your phone\n'
        'If outside, notice your surroundings rather than thinking about worries\n'
        'Finish with 1–2 minutes of slower walking to cool down',
    benefitsRaw:
        'Breaks sedentary time — even 10 minutes reverses blood pooling in the legs\n'
        'Boosts BDNF (brain-derived neurotrophic factor), fueling memory and learning\n'
        'Reduces blood sugar spikes after sitting for long periods\n'
        'Elevates mood through a mild endorphin release\n'
        'A 10-minute walk improves creative thinking by up to 81% (Stanford study)\n'
        'Reduces feelings of restlessness and screen-craving over time',
  ),
  ActivityIdea(
    title: 'Drink Water',
    description:
        'Grab a full glass of water. Staying hydrated improves focus, energy and mood.',
    emoji: '💧',
    category: 'Health',
    durationMinutes: 2,
    stepsRaw:
        'Go to your kitchen or nearest water source\n'
        'Fill a large glass (at least 300 ml) with cool water\n'
        'Drink it slowly — sip by sip rather than gulping\n'
        'While drinking, sit down, breathe and be present — no screen\n'
        'If plain water feels boring, add a slice of lemon or a pinch of salt\n'
        'Aim to finish the full glass within 2–3 minutes',
    benefitsRaw:
        'Even mild dehydration (1–2%) reduces concentration by up to 13%\n'
        'Rehydrating improves short-term memory and reaction time within 20 minutes\n'
        'Supports kidney function and removes metabolic waste products\n'
        'Reduces headaches — the most common cause of mid-day headaches is dehydration\n'
        'Promotes healthy skin, digestion and joint lubrication',
  ),
  ActivityIdea(
    title: 'Write 3 Gratitudes',
    description:
        'Jot down 3 specific things you are grateful for today. Shifts your mindset to positivity.',
    emoji: '📝',
    category: 'Mindfulness',
    durationMinutes: 5,
    stepsRaw:
        'Grab a notebook or open a notes app — write by hand if possible\n'
        'At the top, write today\'s date\n'
        'Think of 3 things that happened today that you are genuinely thankful for\n'
        'Be specific — not just "family" but "my sister texted to check on me today"\n'
        'For each item, write 1–2 sentences about why it matters to you\n'
        'Take a moment to actually feel the gratitude before moving on',
    benefitsRaw:
        'Rewires the brain\'s negativity bias over 3–4 weeks of practice\n'
        'Linked to measurable increases in long-term happiness and life satisfaction\n'
        'Reduces envy, resentment and frustration by shifting focus to abundance\n'
        'Improves sleep quality when practiced at night\n'
        'Strengthens social relationships as you become more appreciative of others',
  ),
  ActivityIdea(
    title: 'Full-Body Stretch',
    description:
        'Slowly stretch your neck, shoulders, back and legs to release built-up tension.',
    emoji: '🤸',
    category: 'Fitness',
    durationMinutes: 5,
    stepsRaw:
        'Stand or sit tall and take 3 deep breaths to begin\n'
        'Neck: slowly tilt your right ear to your right shoulder, hold 20 s, repeat left\n'
        'Shoulders: cross one arm across your chest, hold with opposite hand, 20 s each side\n'
        'Chest: interlace fingers behind your back, push chest forward and hold 20 s\n'
        'Back: sit on a chair and twist gently to each side, hold 20 s each\n'
        'Hamstrings: hinge forward at the hips with soft knees, hold 30 s\n'
        'Hip flexors: step one foot forward into a lunge, hold 30 s each side\n'
        'Never push into sharp pain — stretches should feel like gentle tension',
    benefitsRaw:
        'Relieves muscle tightness caused by prolonged sitting\n'
        'Improves posture by lengthening muscles shortened by hunching\n'
        'Increases blood flow to muscles and connective tissue\n'
        'Reduces risk of injury during physical activity\n'
        'Signals the nervous system to shift from stress mode to rest mode',
  ),
  ActivityIdea(
    title: 'Read a Book Chapter',
    description:
        'Pick up a non-fiction or personal-growth book and read at least one chapter.',
    emoji: '📖',
    category: 'Learning',
    durationMinutes: 15,
    stepsRaw:
        'Choose a physical book or e-reader — avoid reading on your main phone\n'
        'Find a quiet, well-lit spot and sit comfortably\n'
        'Before you start, recall what happened in the last chapter you read\n'
        'Read at a comfortable pace — comprehension matters more than speed\n'
        'Underline or highlight sentences that resonate with you\n'
        'After finishing, close the book and spend 60 seconds recalling the key ideas\n'
        'Write a one-line insight in a notebook to reinforce the memory',
    benefitsRaw:
        'Reading 15–30 minutes a day reduces stress by up to 68% (University of Sussex)\n'
        'Builds vocabulary and verbal intelligence continuously\n'
        'Improves deep focus and the ability to sustain attention\n'
        'Stimulates imagination and analytical thinking\n'
        'Regular readers are on average more empathetic and socially perceptive',
  ),
  ActivityIdea(
    title: '10 Push-Ups',
    description:
        'Drop and do 10 push-ups. A quick burst of exercise boosts energy and mental clarity.',
    emoji: '💪',
    category: 'Fitness',
    durationMinutes: 3,
    stepsRaw:
        'Place your hands on the floor slightly wider than shoulder-width\n'
        'Extend your legs behind you — balance on hands and toes (or knees for modified)\n'
        'Keep your body in a straight line from head to heels — tighten your core\n'
        'Lower your chest towards the floor, bending elbows to about 90 degrees\n'
        'Pause for 1 second at the bottom\n'
        'Push powerfully back up, fully extending your arms\n'
        'Breathe in on the way down, breathe out on the way up\n'
        'Complete 10 reps — rest 60 seconds and try a second set',
    benefitsRaw:
        'Activates chest, shoulders, triceps and core simultaneously\n'
        'Releases endorphins immediately, reducing stress and boosting mood\n'
        'Increases heart rate, sending more oxygen to the brain\n'
        'Builds upper-body strength with zero equipment\n'
        'Counteracts the forward-slouch posture from screen time',
  ),
  ActivityIdea(
    title: 'Tidy Your Space',
    description:
        'Spend a few minutes organising your desk or room. A clean environment fosters a clear mind.',
    emoji: '🏠',
    category: 'Productivity',
    durationMinutes: 10,
    stepsRaw:
        'Set a 10-minute timer so you stay focused\n'
        'Start with flat surfaces — desk, table, bed\n'
        'Group similar items together (books, cables, stationery)\n'
        'Throw away any rubbish or items you no longer need\n'
        'Wipe down surfaces quickly with a cloth if available\n'
        'Put items back intentionally — give everything a defined home\n'
        'Stop when the timer rings',
    benefitsRaw:
        'Visual clutter reduces cognitive bandwidth by up to 20%\n'
        'A tidy environment signals to the brain that things are under control\n'
        'Increases productivity immediately\n'
        'Creates a sense of accomplishment and self-respect\n'
        'Reduces time wasted searching for misplaced items',
  ),
  ActivityIdea(
    title: 'Prepare a Healthy Snack',
    description:
        'Slice some fruit, make a handful of nuts, or blend a quick smoothie to fuel your body.',
    emoji: '🥗',
    category: 'Health',
    durationMinutes: 10,
    stepsRaw:
        'Pick one of: a piece of whole fruit, a handful of nuts, Greek yogurt, sliced vegetables with hummus\n'
        'Wash and prepare your food with care\n'
        'Eat at a table, away from screens\n'
        'Chew slowly — aim for 20–30 chews per bite\n'
        'Notice the taste, texture and smell of the food\n'
        'Drink a glass of water alongside the snack\n'
        'Clean up before you sit down again',
    benefitsRaw:
        'Eating nutritious whole foods stabilises blood sugar, preventing energy crashes\n'
        'Nuts and seeds provide healthy fats essential for brain function\n'
        'Fruit provides natural sugars alongside fibre, antioxidants and vitamins\n'
        'Mindful eating reduces overeating and improves your relationship with food\n'
        'Taking a proper break increases afternoon productivity',
  ),
  ActivityIdea(
    title: 'Call a Friend or Family',
    description:
        'Reconnect with someone you care about. Real conversations strengthen relationships.',
    emoji: '📞',
    category: 'Social',
    durationMinutes: 15,
    stepsRaw:
        'Think of one person you have not spoken to in a while\n'
        'Step somewhere quiet and private before calling\n'
        'Ask genuinely "How are you really doing?" and listen fully\n'
        'Do not fill silences immediately — let the other person speak\n'
        'Share something real about your own life\n'
        'Before hanging up, make a plan to speak again\n'
        'After the call, notice how you feel compared to before',
    benefitsRaw:
        'Strong social connections are the biggest predictor of long-term happiness\n'
        'A warm phone call lowers cortisol at the same level as a physical hug\n'
        'Reduces feelings of loneliness and isolation\n'
        'Strengthens the bond — relationships need regular investment\n'
        'Practicing deep listening builds emotional intelligence',
  ),
  ActivityIdea(
    title: 'Plan Tomorrow',
    description:
        'Write your top 3 priorities for tomorrow so you start the next day with clarity and purpose.',
    emoji: '📋',
    category: 'Productivity',
    durationMinutes: 5,
    stepsRaw:
        'Grab a notebook, planner or notes app\n'
        'Review what you did today in 30 seconds\n'
        'Ask yourself: "What are the 3 most important things I must do tomorrow?"\n'
        'Write down these 3 tasks in order of importance — no more than 3\n'
        'For each task, write the very first action you need to take\n'
        'Set out anything you will need tomorrow (notebook, clothes, keys)\n'
        'Close the planner — you are done thinking about work for today',
    benefitsRaw:
        'Reduces the cognitive load of "what do I do next?" in the morning\n'
        'Starting the day with a clear intention increases completion of meaningful work\n'
        'Writing down tasks offloads them from working memory, reducing anxiety\n'
        'Creates a closing ritual that signals the brain to rest\n'
        'The 3-priority rule prevents overwhelm',
  ),
  ActivityIdea(
    title: '5-Minute Yoga',
    description:
        'Flow through a few simple poses — child pose, cat-cow, downward dog — to improve flexibility.',
    emoji: '🧘',
    category: 'Fitness',
    durationMinutes: 5,
    stepsRaw:
        'Stand barefoot on a mat or carpet and take 5 deep breaths\n'
        'Cat-Cow (1 min): on hands and knees, inhale to arch (cow), exhale to round (cat), repeat 8x\n'
        'Child\'s Pose (1 min): sit back onto heels, stretch arms forward, breathe deeply\n'
        'Downward Dog (1 min): push up into an inverted V, press heels toward the floor\n'
        'Low Lunge (30 s each side): step one foot forward, lower back knee, reach arms overhead\n'
        'Seated Forward Fold (1 min): sit with legs straight, hinge forward from hips\n'
        'Finish in Corpse Pose: lie flat, close your eyes, breathe naturally for 30 seconds',
    benefitsRaw:
        'Improves spinal mobility and counteracts compression from sitting\n'
        'Activates the parasympathetic nervous system within 3–5 minutes\n'
        'Increases body awareness, helping you catch tension before it becomes pain\n'
        'Reduces lower-back pain, one of the most common complaints from desk workers\n'
        'Combines movement, breath and presence for mental calm',
  ),
  ActivityIdea(
    title: 'Sketch or Doodle',
    description:
        'Grab pen and paper and draw freely. Creative expression reduces stress and sparks creativity.',
    emoji: '✏️',
    category: 'Creativity',
    durationMinutes: 10,
    stepsRaw:
        'Get a plain sheet of paper and a pen or pencil — no special tools needed\n'
        'Start without a plan — begin with a single shape, line or word\n'
        'Let your hand move freely without judging what appears on the page\n'
        'Try zentangle (repeating patterns) or blind contour (draw without looking at the paper)\n'
        'Do not erase — imperfections are part of the process\n'
        'Keep going for the full 10 minutes even if you feel stuck\n'
        'At the end, look at what you made without judging it',
    benefitsRaw:
        'Activates the right hemisphere, shifting you out of analytical overthinking\n'
        'Reduces cortisol levels comparably to other mindfulness activities\n'
        'Boosts divergent thinking — generating multiple creative solutions\n'
        'Gives the verbal mind a rest, which often leads to unexpected insights\n'
        'Builds confidence to act without needing perfection first',
  ),
  ActivityIdea(
    title: 'Learn 5 New Words',
    description:
        'Open a dictionary or language app and learn 5 new words in any language you want to improve.',
    emoji: '📚',
    category: 'Learning',
    durationMinutes: 10,
    stepsRaw:
        'Choose a language you are learning or want to improve\n'
        'Open a dictionary, flashcard app or Google "interesting words"\n'
        'Pick 5 words that are genuinely unfamiliar and interesting\n'
        'For each word: read the definition, say it aloud, read the example sentence\n'
        'Write each word and its meaning by hand in a vocabulary notebook\n'
        'Try to use each word in a sentence of your own\n'
        'Revisit these words tomorrow to move them to long-term memory',
    benefitsRaw:
        'Vocabulary is one of the strongest predictors of cognitive ability and career success\n'
        'Learning new words builds new neural pathways and keeps the brain plastic\n'
        'A richer vocabulary allows you to express thoughts more precisely\n'
        'Spaced repetition is the most efficient form of learning\n'
        '5 words a day = 1,825 words a year',
  ),
  ActivityIdea(
    title: '30 Jumping Jacks',
    description:
        'Do 30 jumping jacks to rapidly raise your heart rate and shake off mental fatigue.',
    emoji: '🏃',
    category: 'Fitness',
    durationMinutes: 3,
    stepsRaw:
        'Stand with feet together and arms at your sides\n'
        'Jump and simultaneously spread your feet wider than shoulder-width\n'
        'Raise both arms out and overhead so your hands nearly meet\n'
        'Jump back to the starting position — that is one rep\n'
        'Keep a steady rhythm — aim for one jump per second\n'
        'Breathe continuously — do not hold your breath\n'
        'Complete 30 reps; rest and repeat if you want more intensity',
    benefitsRaw:
        'Raises heart rate within 30 seconds, delivering more oxygen to the brain\n'
        'Triggers a rapid endorphin release that lifts mood within 2–3 minutes\n'
        'Burns roughly 8–10 calories per minute\n'
        'Improves coordination by engaging multiple muscle groups simultaneously\n'
        'Acts as a pattern interrupt — immediately breaks the trance of screen use',
  ),
  ActivityIdea(
    title: 'Brew Herbal Tea',
    description:
        'Make a calming cup of chamomile, peppermint or green tea. A ritual that soothes the mind.',
    emoji: '🍵',
    category: 'Health',
    durationMinutes: 5,
    stepsRaw:
        'Choose your tea: chamomile (calming), peppermint (focus), green tea (energy), ginger (warming)\n'
        'Boil fresh water — green tea brews best at 70–80°C, herbal at 95°C\n'
        'Place the tea bag in your cup\n'
        'Pour the water and steep: green tea 2–3 min, herbal 5–7 min\n'
        'While it steeps, stand without your phone and just be present\n'
        'Wrap both hands around the warm cup and take 5 slow breaths\n'
        'Sip slowly — taste each sip rather than drinking absent-mindedly',
    benefitsRaw:
        'Chamomile contains apigenin, which binds to brain receptors to promote calm\n'
        'Green tea provides L-theanine — alert relaxation without coffee jitters\n'
        'Peppermint tea increases alertness and has been shown to improve memory\n'
        'The ritual of making tea is itself a mindfulness practice\n'
        'Warm liquids soothe the digestive system and support the gut-brain axis',
  ),
  ActivityIdea(
    title: 'Mindful Listening',
    description:
        'Close your eyes and spend 5 minutes paying close attention to the sounds around you.',
    emoji: '👂',
    category: 'Mindfulness',
    durationMinutes: 5,
    stepsRaw:
        'Sit or lie down comfortably\n'
        'Set a timer for 5 minutes\n'
        'Close your eyes and take 3 slow breaths to arrive in the present\n'
        'Notice the nearest sounds first, then expand to distant sounds\n'
        'Label each sound neutrally: "traffic", "fan", "bird", "voice"\n'
        'When your mind wanders to thoughts, return focus to the sounds\n'
        'Notice the silence between sounds — sit with it',
    benefitsRaw:
        'Trains the nervous system to process input without reactivity\n'
        'Quickly anchors attention to the present moment, interrupting rumination\n'
        'Improves active listening skills in conversations\n'
        'Requires zero technique — accessible to anyone at any moment\n'
        '5 minutes of sensory mindfulness reduces anxiety as effectively as 15 minutes of breathing exercises',
  ),
  ActivityIdea(
    title: 'Journal Your Feelings',
    description:
        'Write freely about how you feel right now. Putting emotions into words reduces stress.',
    emoji: '✍️',
    category: 'Mindfulness',
    durationMinutes: 10,
    stepsRaw:
        'Get a private notebook or open a secure notes app\n'
        'Set a timer for 10 minutes and write continuously — do not stop\n'
        'Start with: "Right now I feel..." and let the words come\n'
        'Write whatever is true — anger, confusion, joy — all of it is valid\n'
        'If you get stuck, write "I don\'t know what to write" until something surfaces\n'
        'Do not re-read what you have written until the timer ends\n'
        'When the timer rings, close the journal and just breathe',
    benefitsRaw:
        'Expressive writing improves immune function over 4 days of practice\n'
        'Naming emotions reduces activity in the amygdala — the brain\'s alarm centre\n'
        'Helps untangle complex feelings by externalising them\n'
        'Reveals patterns in your emotional life over weeks\n'
        'Regular journallers report lower levels of anxiety and stress',
  ),
  ActivityIdea(
    title: 'Do 20 Squats',
    description:
        'Stand up and do 20 body-weight squats to strengthen your legs and get blood flowing.',
    emoji: '🏋️',
    category: 'Fitness',
    durationMinutes: 3,
    stepsRaw:
        'Stand with feet shoulder-width apart, toes turned out slightly\n'
        'Hold arms straight out in front or cross them at your chest\n'
        'Inhale and push your hips back and down as if sitting into a chair\n'
        'Lower until thighs are at least parallel to the floor\n'
        'Keep your chest up and knees tracking over your toes\n'
        'Exhale and push through your heels to stand back up\n'
        'Complete 20 reps — rest 60 seconds and repeat if possible',
    benefitsRaw:
        'Engages the largest muscle groups in the body — maximum calorie burn\n'
        'Counteracts hip tightness and weakness from prolonged sitting\n'
        'Triggers growth hormone release, supporting muscle and metabolism\n'
        'Improves mobility and functional strength for everyday movement\n'
        'Squatting regularly is linked to reduced lower-back pain',
  ),
  ActivityIdea(
    title: 'Recall Three Wins',
    description:
        'Think of three things you did well today, however small. Builds confidence and self-awareness.',
    emoji: '🌟',
    category: 'Mindfulness',
    durationMinutes: 5,
    stepsRaw:
        'Sit quietly and take 3 slow breaths to shift out of autopilot\n'
        'Ask yourself: "What went well today?" — give yourself 60 seconds to scan the day\n'
        'Pick 3 moments, however small\n'
        'For each win, say or write: "I did [X] and it mattered because [Y]"\n'
        'Let yourself genuinely feel good about each one\n'
        'If you struggle to find 3, lower the bar — completing this exercise is itself a win\n'
        'Optionally: close your eyes and mentally replay each moment',
    benefitsRaw:
        'Trains the brain to notice positive events, overriding the negativity bias\n'
        'Builds genuine self-confidence grounded in evidence\n'
        'Strengthens self-awareness — you cannot improve what you do not notice\n'
        'Provides emotional momentum for tomorrow\'s challenges\n'
        'Used by elite athletes and high performers as part of their daily review',
  ),
];

/// Represents a self-improvement activity suggestion shown to users
/// during their digital restriction period.
class ActivityIdea {
  final int? id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final int durationMinutes;
  /// Newline-separated how-to steps stored as a single text column.
  final String stepsRaw;
  /// Newline-separated benefit lines stored as a single text column.
  final String benefitsRaw;

  const ActivityIdea({
    this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.durationMinutes,
    this.stepsRaw = '',
    this.benefitsRaw = '',
  });

  List<String> get steps =>
      stepsRaw.split('\n').where((s) => s.trim().isNotEmpty).toList();

  List<String> get benefits =>
      benefitsRaw.split('\n').where((s) => s.trim().isNotEmpty).toList();

  factory ActivityIdea.fromMap(Map<String, dynamic> map) {
    return ActivityIdea(
      id: map['id'] as int?,
      title: (map['title'] as Object?)?.toString() ?? '',
      description: (map['description'] as Object?)?.toString() ?? '',
      emoji: (map['emoji'] as Object?)?.toString() ?? '✨',
      category: (map['category'] as Object?)?.toString() ?? 'Mindfulness',
      durationMinutes: (map['duration_minutes'] as int?) ?? 10,
      stepsRaw: (map['steps'] as Object?)?.toString() ?? '',
      benefitsRaw: (map['benefits'] as Object?)?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'category': category,
      'duration_minutes': durationMinutes,
      'steps': stepsRaw,
      'benefits': benefitsRaw,
    };
  }
}
