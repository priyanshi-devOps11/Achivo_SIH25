import { motion } from 'motion/react';
import { Globe, Map, GraduationCap, ChevronRight, MapPin } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { useState } from 'react';

const countries = [
  { value: 'us', label: 'United States' },
  { value: 'uk', label: 'United Kingdom' },
  { value: 'canada', label: 'Canada' },
  { value: 'australia', label: 'Australia' },
  { value: 'india', label: 'India' },
  { value: 'germany', label: 'Germany' },
  { value: 'france', label: 'France' },
];

const states = {
  us: [
    { value: 'ca', label: 'California' },
    { value: 'ny', label: 'New York' },
    { value: 'tx', label: 'Texas' },
    { value: 'fl', label: 'Florida' },
  ],
  uk: [
    { value: 'england', label: 'England' },
    { value: 'scotland', label: 'Scotland' },
    { value: 'wales', label: 'Wales' },
  ],
  india: [
    { value: 'maharashtra', label: 'Maharashtra' },
    { value: 'karnataka', label: 'Karnataka' },
    { value: 'delhi', label: 'Delhi' },
    { value: 'gujarat', label: 'Gujarat' },
  ],
};

const institutes = [
  { value: 'harvard', label: 'Harvard University' },
  { value: 'mit', label: 'MIT' },
  { value: 'stanford', label: 'Stanford University' },
  { value: 'oxford', label: 'Oxford University' },
  { value: 'cambridge', label: 'Cambridge University' },
  { value: 'iit-bombay', label: 'IIT Bombay' },
  { value: 'iit-delhi', label: 'IIT Delhi' },
];

interface WelcomeFormProps {
onNext: () => void;
}

export function WelcomeForm({ onNext }: WelcomeFormProps) {
const [selectedCountry, setSelectedCountry] = useState('');
const [selectedState, setSelectedState] = useState('');
const [selectedInstitute, setSelectedInstitute] = useState('');

const availableStates = selectedCountry ? states[selectedCountry as keyof typeof states] || [] : [];

const handleContinue = () => {
if (selectedCountry && selectedState && selectedInstitute) {
onNext();
}
};

return (
<div className="relative min-h-screen overflow-hidden">
{/* Brighter Material You Inspired Gradient Background */}
<div className="absolute inset-0 bg-gradient-to-br from-blue-100 via-purple-100 to-pink-100">
{/* Flowing gradient shapes - brighter */}
<div className="absolute top-0 left-0 w-full h-full">
<motion.div
initial={{ scale: 0.8, opacity: 0 }}
animate={{ scale: 1, opacity: 1 }}
transition={{ duration: 2, ease: "easeOut" }}
className="absolute -top-1/4 -left-1/4 w-3/4 h-3/4 bg-gradient-to-br from-blue-400/25 via-purple-400/20 to-transparent rounded-full blur-3xl"
/>
<motion.div
initial={{ scale: 0.8, opacity: 0 }}
animate={{ scale: 1, opacity: 1 }}
transition={{ duration: 2.5, ease: "easeOut", delay: 0.3 }}
className="absolute -bottom-1/4 -right-1/4 w-3/4 h-3/4 bg-gradient-to-tl from-pink-400/25 via-purple-400/20 to-transparent rounded-full blur-3xl"
/>
<motion.div
initial={{ scale: 0.8, opacity: 0 }}
animate={{ scale: 1, opacity: 1 }}
transition={{ duration: 2.2, ease: "easeOut", delay: 0.6 }}
className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-1/2 h-1/2 bg-gradient-to-r from-indigo-400/20 via-blue-400/15 to-cyan-400/20 rounded-full blur-2xl"
/>
</div>
</div>

{/* Academic Micro-illustrations */}
<div className="absolute inset-0 overflow-hidden">
{/* Globe icon - top left */}
<motion.div
initial={{ opacity: 0, rotate: -10 }}
animate={{ opacity: 0.1, rotate: 0 }}
transition={{ duration: 3, ease: "easeOut", delay: 1 }}
className="absolute top-16 left-12 text-blue-600"
>
<Globe size={100} strokeWidth={0.8} />
</motion.div>

{/* University building - top right */}
<motion.div
initial={{ opacity: 0, y: -20 }}
animate={{ opacity: 0.1, y: 0 }}
transition={{ duration: 3, ease: "easeOut", delay: 1.3 }}
className="absolute top-20 right-16 text-purple-600"
>
<GraduationCap size={110} strokeWidth={0.8} />
</motion.div>

{/* Map icon - bottom left */}
<motion.div
initial={{ opacity: 0, scale: 0.8 }}
animate={{ opacity: 0.1, scale: 1 }}
transition={{ duration: 3, ease: "easeOut", delay: 1.6 }}
className="absolute bottom-32 left-16 text-indigo-600"
>
<Map size={120} strokeWidth={0.8} />
</motion.div>

{/* Additional smaller icons */}
<motion.div
initial={{ opacity: 0, scale: 0.5 }}
animate={{ opacity: 0.06, scale: 1 }}
transition={{ duration: 4, ease: "easeOut", delay: 2 }}
className="absolute bottom-16 right-20 text-pink-600"
>
<MapPin size={80} strokeWidth={0.6} />
</motion.div>

<motion.div
initial={{ opacity: 0, scale: 0.5 }}
animate={{ opacity: 0.06, scale: 1 }}
transition={{ duration: 4, ease: "easeOut", delay: 2.3 }}
className="absolute top-1/2 right-8 text-cyan-600"
>
<Globe size={70} strokeWidth={0.6} />
</motion.div>
</div>

{/* Main Content */}
<div className="relative z-10 flex flex-col items-center justify-center min-h-screen px-6 py-12">
{/* Welcome Headline with Glow */}
<motion.div
initial={{ opacity: 0, y: 30 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1.2, ease: "easeOut", delay: 0.3 }}
className="text-center mb-4"
>
<h1 className="text-5xl md:text-6xl font-bold relative">
<span className="bg-gradient-to-r from-slate-800 via-purple-800 to-slate-800 bg-clip-text text-transparent">
Welcome!
</span>
{/* Glow effect */}
<div className="absolute inset-0 bg-gradient-to-r from-purple-400/20 to-blue-400/20 blur-2xl -z-10 scale-110" />
</h1>
</motion.div>

{/* Inspiring Tagline */}
<motion.div
initial={{ opacity: 0, y: 20 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1, ease: "easeOut", delay: 0.6 }}
className="text-center mb-12"
>
<p className="text-xl md:text-2xl text-slate-700 max-w-lg mx-auto leading-relaxed">
Your journey of achievements starts here
</p>
</motion.div>

{/* Form Section */}
<motion.div
initial={{ opacity: 0, y: 30 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1, ease: "easeOut", delay: 0.9 }}
className="w-full max-w-md space-y-6"
>
{/* Country Dropdown */}
<div className="space-y-2">
<label className="text-slate-700 block">Choose your country</label>
<Select value={selectedCountry} onValueChange={setSelectedCountry}>
<SelectTrigger className="w-full h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90">
<SelectValue placeholder="Select country" />
</SelectTrigger>
<SelectContent className="rounded-2xl shadow-xl border-slate-200/50 bg-white/95 backdrop-blur-md">
{countries.map((country) => (
<SelectItem
key={country.value}
value={country.value}
className="rounded-xl hover:bg-gradient-to-r hover:from-purple-50 hover:to-blue-50 transition-all"
>
{country.label}
</SelectItem>
))}
</SelectContent>
</Select>
</div>

{/* State Dropdown */}
<div className="space-y-2">
<label className="text-slate-700 block">Choose your state</label>
<Select
value={selectedState}
onValueChange={setSelectedState}
disabled={!selectedCountry}
>
<SelectTrigger className="w-full h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 disabled:opacity-50">
<SelectValue placeholder="Select state" />
</SelectTrigger>
<SelectContent className="rounded-2xl shadow-xl border-slate-200/50 bg-white/95 backdrop-blur-md">
{availableStates.map((state) => (
<SelectItem
key={state.value}
value={state.value}
className="rounded-xl hover:bg-gradient-to-r hover:from-purple-50 hover:to-blue-50 transition-all"
>
{state.label}
</SelectItem>
))}
</SelectContent>
</Select>
</div>

{/* Institute Dropdown */}
<div className="space-y-2">
<label className="text-slate-700 block">Choose your institute</label>
<Select value={selectedInstitute} onValueChange={setSelectedInstitute}>
<SelectTrigger className="w-full h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90">
<SelectValue placeholder="Select institute" />
</SelectTrigger>
<SelectContent className="rounded-2xl shadow-xl border-slate-200/50 bg-white/95 backdrop-blur-md">
{institutes.map((institute) => (
<SelectItem
key={institute.value}
value={institute.value}
className="rounded-xl hover:bg-gradient-to-r hover:from-purple-50 hover:to-blue-50 transition-all"
>
{institute.label}
</SelectItem>
))}
</SelectContent>
</Select>
</div>
</motion.div>

{/* Submit Button */}
<motion.div
initial={{ opacity: 0, y: 20 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 1, ease: "easeOut", delay: 1.2 }}
className="mt-12"
>
<motion.button
onClick={handleContinue}
whileHover={{ scale: 1.02 }}
whileTap={{ scale: 0.98 }}
disabled={!selectedCountry || !selectedState || !selectedInstitute}
className="relative group disabled:opacity-50 disabled:cursor-not-allowed"
>
{/* Glow effect */}
<div className="absolute inset-0 bg-gradient-to-r from-purple-400 to-blue-400 rounded-2xl blur-xl opacity-60 scale-110 group-hover:opacity-80 transition-opacity group-disabled:opacity-30" />

{/* Button content */}
<div className="relative bg-gradient-to-r from-purple-500 to-blue-500 rounded-2xl px-12 py-4 shadow-2xl flex items-center gap-3 group-hover:from-purple-600 group-hover:to-blue-600 transition-all group-disabled:from-gray-400 group-disabled:to-gray-500">
<span className="text-white drop-shadow-lg text-lg">Continue</span>
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
<div className="absolute inset-0 bg-gradient-to-t from-white/5 via-transparent to-white/10 pointer-events-none" />
</div>
);
}