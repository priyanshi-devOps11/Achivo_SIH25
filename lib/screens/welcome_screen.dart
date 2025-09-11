import { motion } from 'motion/react';
import { BookOpen, Award, Users, ChevronRight } from 'lucide-react';

interface WelcomeScreenProps {
onNext: () => void;
}

export function WelcomeScreen({ onNext }: WelcomeScreenProps) {
return (
<div className="relative min-h-screen overflow-hidden">
{/* Material You Inspired Gradient Background */}
<div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50">
{/* Flowing gradient shapes */}
<div className="absolute top-0 left-0 w-full h-full">
<motion.div
initial={{ scale: 0.8, opacity: 0 }}
animate={{ scale: 1, opacity: 1 }}
transition={{ duration: 2, ease: "easeOut" }}
className="absolute -top-1/4 -left-1/4 w-3/4 h-3/4 bg-gradient-to-br from-blue-400/20 via-purple-400/15 to-transparent rounded-full blur-3xl"
/>
<motion.div
initial={{ scale: 0.8, opacity: 0 }}
animate={{ scale: 1, opacity: 1 }}
transition={{ duration: 2.5, ease: "easeOut", delay: 0.3 }}
className="absolute -bottom-1/4 -right-1/4 w-3/4 h-3/4 bg-gradient-to-tl from-pink-400/20 via-purple-400/15 to-transparent rounded-full blur-3xl"
/>
<motion.div
initial={{ scale: 0.8, opacity: 0 }}
animate={{ scale: 1, opacity: 1 }}
transition={{ duration: 2.2, ease: "easeOut", delay: 0.6 }}
className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-1/2 h-1/2 bg-gradient-to-r from-indigo-400/15 via-blue-400/10 to-cyan-400/15 rounded-full blur-2xl"
/>
</div>
</div>

{/* Subtle Micro-illustrations */}
<div className="absolute inset-0 overflow-hidden">
{/* Book icon - top left */}
<motion.div
initial={{ opacity: 0, y: -20 }}
animate={{ opacity: 0.08, y: 0 }}
transition={{ duration: 3, ease: "easeOut", delay: 1 }}
className="absolute top-20 left-16 text-blue-600"
>
<BookOpen size={120} strokeWidth={0.8} />
</motion.div>

{/* Award icon - top right */}
<motion.div
initial={{ opacity: 0, y: -20 }}
animate={{ opacity: 0.08, y: 0 }}
transition={{ duration: 3, ease: "easeOut", delay: 1.3 }}
className="absolute top-32 right-20 text-purple-600"
>
<Award size={100} strokeWidth={0.8} />
</motion.div>

{/* Teamwork icon - bottom left */}
<motion.div
initial={{ opacity: 0, y: 20 }}
animate={{ opacity: 0.08, y: 0 }}
transition={{ duration: 3, ease: "easeOut", delay: 1.6 }}
className="absolute bottom-40 left-20 text-pink-600"
>
<Users size={110} strokeWidth={0.8} />
</motion.div>

{/* Additional smaller icons for richness */}
<motion.div
initial={{ opacity: 0, scale: 0.5 }}
animate={{ opacity: 0.05, scale: 1 }}
transition={{ duration: 4, ease: "easeOut", delay: 2 }}
className="absolute bottom-20 right-16 text-indigo-600"
>
<BookOpen size={80} strokeWidth={0.6} />
</motion.div>

<motion.div
initial={{ opacity: 0, scale: 0.5 }}
animate={{ opacity: 0.05, scale: 1 }}
transition={{ duration: 4, ease: "easeOut", delay: 2.3 }}
className="absolute top-1/2 left-8 text-cyan-600"
>
<Award size={70} strokeWidth={0.6} />
</motion.div>
</div>

{/* Main Content */}
<div className="relative z-10 flex flex-col items-center justify-center min-h-screen px-6">
{/* App Name */}
<motion.div
initial={{ opacity: 0, y: 30 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1.2, ease: "easeOut", delay: 0.5 }}
className="text-center mb-8"
>
<h1 className="text-7xl md:text-8xl lg:text-9xl font-bold bg-gradient-to-r from-slate-900 via-purple-900 to-slate-900 bg-clip-text text-transparent tracking-tight">
Achivo
</h1>
</motion.div>

{/* Tagline */}
<motion.div
initial={{ opacity: 0, y: 20 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1, ease: "easeOut", delay: 1 }}
className="text-center mb-20"
>
<p className="text-lg md:text-xl text-slate-600 max-w-md mx-auto leading-relaxed">
Where student activities turn into achievements
</p>
</motion.div>

{/* Next Button with Glowing Arrow */}
<motion.div
initial={{ opacity: 0, y: 20 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1, ease: "easeOut", delay: 1.5 }}
className="absolute bottom-12 left-1/2 transform -translate-x-1/2"
>
<motion.button
onClick={onNext}
whileHover={{ scale: 1.05 }}
whileTap={{ scale: 0.95 }}
animate={{
y: [0, -4, 0],
}}
transition={{
duration: 2,
repeat: Infinity,
ease: "easeInOut"
}}
className="relative group"
>
{/* Glow effect */}
<div className="absolute inset-0 bg-gradient-to-r from-purple-400 to-blue-400 rounded-full blur-xl opacity-60 scale-110 group-hover:opacity-80 transition-opacity" />

{/* Button content */}
<div className="relative bg-gradient-to-r from-purple-500 to-blue-500 rounded-full px-6 py-4 shadow-2xl flex items-center gap-3 group-hover:from-purple-600 group-hover:to-blue-600 transition-all">
<span className="text-white drop-shadow-lg">Next</span>
<ChevronRight
size={24}
className="text-white drop-shadow-lg"
strokeWidth={2.5}
/>
</div>
</motion.button>
</motion.div>
</div>

{/* Subtle overlay for depth */}
<div className="absolute inset-0 bg-gradient-to-t from-white/10 via-transparent to-white/20 pointer-events-none" />
</div>
);
}