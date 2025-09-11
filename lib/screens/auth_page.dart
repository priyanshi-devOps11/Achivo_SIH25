import { motion } from 'motion/react';
import { User, Mail, Lock, ChevronRight, BookOpen, Award, Users } from 'lucide-react';
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { useState } from 'react';

export function AuthPage() {
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 2000));
  setIsLoading(false);
  };

  return (
  <div className="relative min-h-screen overflow-hidden">
  {/* Enhanced Material You Inspired Gradient Background */}
  <div className="absolute inset-0 bg-gradient-to-br from-indigo-50 via-purple-50 to-blue-50">
  {/* Flowing gradient shapes */}
  <div className="absolute top-0 left-0 w-full h-full">
  <motion.div
  initial={{ scale: 0.8, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  transition={{ duration: 2, ease: "easeOut" }}
  className="absolute -top-1/3 -left-1/4 w-4/5 h-4/5 bg-gradient-to-br from-indigo-400/20 via-purple-400/15 to-transparent rounded-full blur-3xl"
  />
  <motion.div
  initial={{ scale: 0.8, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  transition={{ duration: 2.5, ease: "easeOut", delay: 0.3 }}
  className="absolute -bottom-1/3 -right-1/4 w-4/5 h-4/5 bg-gradient-to-tl from-blue-400/20 via-cyan-400/15 to-transparent rounded-full blur-3xl"
  />
  <motion.div
  initial={{ scale: 0.8, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  transition={{ duration: 2.2, ease: "easeOut", delay: 0.6 }}
  className="absolute top-1/3 left-1/3 w-1/2 h-1/2 bg-gradient-to-r from-purple-400/15 via-indigo-400/10 to-blue-400/15 rounded-full blur-2xl"
  />
  </div>
  </div>

  {/* Subtle Achievement Micro-illustrations */}
  <div className="absolute inset-0 overflow-hidden">
  {/* Book icon - top left */}
  <motion.div
  initial={{ opacity: 0, y: -20, rotate: -5 }}
  animate={{ opacity: 0.06, y: 0, rotate: 0 }}
  transition={{ duration: 3, ease: "easeOut", delay: 1 }}
  className="absolute top-20 left-16 text-indigo-500"
  >
  <BookOpen size={90} strokeWidth={0.8} />
  </motion.div>

  {/* Award icon - top right */}
  <motion.div
  initial={{ opacity: 0, scale: 0.8 }}
  animate={{ opacity: 0.06, scale: 1 }}
  transition={{ duration: 3, ease: "easeOut", delay: 1.3 }}
  className="absolute top-32 right-20 text-purple-500"
  >
  <Award size={80} strokeWidth={0.8} />
  </motion.div>

  {/* Users icon - bottom left */}
  <motion.div
  initial={{ opacity: 0, x: -20 }}
  animate={{ opacity: 0.06, x: 0 }}
  transition={{ duration: 3, ease: "easeOut", delay: 1.6 }}
  className="absolute bottom-32 left-12 text-blue-500"
  >
  <Users size={85} strokeWidth={0.8} />
  </motion.div>

  {/* Additional decorative icons */}
  <motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 0.04 }}
  transition={{ duration: 4, ease: "easeOut", delay: 2 }}
  className="absolute bottom-20 right-16 text-cyan-500"
  >
  <BookOpen size={60} strokeWidth={0.6} />
  </motion.div>

  <motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 0.04 }}
  transition={{ duration: 4, ease: "easeOut", delay: 2.3 }}
  className="absolute top-1/2 left-8 text-indigo-400"
  >
  <Award size={55} strokeWidth={0.6} />
  </motion.div>
  </div>

  {/* Main Content */}
  <div className="relative z-10 flex flex-col items-center justify-center min-h-screen px-6 py-12">
  {/* Header */}
  <motion.div
  initial={{ opacity: 0, y: 30 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 1.2, ease: "easeOut", delay: 0.3 }}
  className="text-center mb-8"
  >
  <h1 className="text-4xl md:text-5xl font-bold relative mb-3">
  <span className="bg-gradient-to-r from-slate-800 via-indigo-800 to-slate-800 bg-clip-text text-transparent">
  Join Achivo
  </span>
  {/* Glow effect */}
  <div className="absolute inset-0 bg-gradient-to-r from-indigo-400/15 to-purple-400/15 blur-2xl -z-10 scale-110" />
  </h1>
  <p className="text-lg text-slate-600 max-w-md mx-auto">
  Start your achievement journey today
  </p>
  </motion.div>

  {/* Auth Tabs */}
  <motion.div
  initial={{ opacity: 0, y: 30 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 1, ease: "easeOut", delay: 0.6 }}
  className="w-full max-w-md"
  >
  <Tabs defaultValue="register" className="w-full">
  <TabsList className="grid w-full grid-cols-2 mb-8 bg-white/60 backdrop-blur-sm rounded-2xl p-1 shadow-lg">
  <TabsTrigger
  value="register"
  className="rounded-xl data-[state=active]:bg-gradient-to-r data-[state=active]:from-indigo-500 data-[state=active]:to-purple-500 data-[state=active]:text-white transition-all duration-300"
  >
  Register
  </TabsTrigger>
  <TabsTrigger
  value="login"
  className="rounded-xl data-[state=active]:bg-gradient-to-r data-[state=active]:from-indigo-500 data-[state=active]:to-purple-500 data-[state=active]:text-white transition-all duration-300"
  >
  Login
  </TabsTrigger>
  </TabsList>

  {/* Register Form */}
  <TabsContent value="register" className="space-y-6">
  <form onSubmit={handleSubmit} className="space-y-6">
  <div className="space-y-4">
  <div className="space-y-2">
  <Label htmlFor="fullName" className="text-slate-700">Full Name</Label>
  <div className="relative">
  <User className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
  <Input
  id="fullName"
  type="text"
  placeholder="Enter your full name"
  className="pl-12 h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 focus:bg-white/95"
  required
  />
  </div>
  </div>

  <div className="space-y-2">
  <Label htmlFor="email" className="text-slate-700">Email</Label>
  <div className="relative">
  <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
  <Input
  id="email"
  type="email"
  placeholder="Enter your email"
  className="pl-12 h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 focus:bg-white/95"
  required
  />
  </div>
  </div>

  <div className="space-y-2">
  <Label htmlFor="password" className="text-slate-700">Password</Label>
  <div className="relative">
  <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
  <Input
  id="password"
  type="password"
  placeholder="Create a password"
  className="pl-12 h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 focus:bg-white/95"
  required
  />
  </div>
  </div>

  <div className="space-y-2">
  <Label htmlFor="confirmPassword" className="text-slate-700">Confirm Password</Label>
  <div className="relative">
  <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
  <Input
  id="confirmPassword"
  type="password"
  placeholder="Confirm your password"
  className="pl-12 h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 focus:bg-white/95"
  required
  />
  </div>
  </div>
  </div>

  <motion.div
  whileHover={{ scale: 1.02 }}
  whileTap={{ scale: 0.98 }}
  className="pt-4"
  >
  <Button
  type="submit"
  disabled={isLoading}
  className="w-full h-14 bg-gradient-to-r from-indigo-500 to-purple-500 hover:from-indigo-600 hover:to-purple-600 text-white rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 relative group"
  >
  {/* Glow effect */}
  <div className="absolute inset-0 bg-gradient-to-r from-indigo-400 to-purple-400 rounded-2xl blur-xl opacity-60 scale-110 group-hover:opacity-80 transition-opacity" />

  <span className="relative flex items-center gap-3 text-lg">
  {isLoading ? (
  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
  ) : (
  <>
  Create Account
  <ChevronRight size={20} />
  </>
  )}
  </span>
  </Button>
  </motion.div>
  </form>
  </TabsContent>

  {/* Login Form */}
  <TabsContent value="login" className="space-y-6">
  <form onSubmit={handleSubmit} className="space-y-6">
  <div className="space-y-4">
  <div className="space-y-2">
  <Label htmlFor="loginEmail" className="text-slate-700">Email</Label>
  <div className="relative">
  <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
  <Input
  id="loginEmail"
  type="email"
  placeholder="Enter your email"
  className="pl-12 h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 focus:bg-white/95"
  required
  />
  </div>
  </div>

  <div className="space-y-2">
  <Label htmlFor="loginPassword" className="text-slate-700">Password</Label>
  <div className="relative">
  <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
  <Input
  id="loginPassword"
  type="password"
  placeholder="Enter your password"
  className="pl-12 h-14 bg-white/80 backdrop-blur-sm border-slate-200/50 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:bg-white/90 focus:bg-white/95"
  required
  />
  </div>
  </div>
  </div>

  <div className="flex items-center justify-between text-sm">
  <label className="flex items-center space-x-2 text-slate-600">
  <input type="checkbox" className="rounded border-slate-300" />
  <span>Remember me</span>
  </label>
  <button type="button" className="text-indigo-600 hover:text-indigo-700 transition-colors">
  Forgot password?
  </button>
  </div>

  <motion.div
  whileHover={{ scale: 1.02 }}
  whileTap={{ scale: 0.98 }}
  className="pt-4"
  >
  <Button
  type="submit"
  disabled={isLoading}
  className="w-full h-14 bg-gradient-to-r from-indigo-500 to-purple-500 hover:from-indigo-600 hover:to-purple-600 text-white rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 relative group"
  >
  {/* Glow effect */}
  <div className="absolute inset-0 bg-gradient-to-r from-indigo-400 to-purple-400 rounded-2xl blur-xl opacity-60 scale-110 group-hover:opacity-80 transition-opacity" />

  <span className="relative flex items-center gap-3 text-lg">
  {isLoading ? (
  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
  ) : (
  <>
  Sign In
  <ChevronRight size={20} />
  </>
  )}
  </span>
  </Button>
  </motion.div>
  </form>
  </TabsContent>
  </Tabs>
  </motion.div>

  {/* Footer */}
  <motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{ duration: 1, ease: "easeOut", delay: 1.2 }}
  className="mt-8 text-center text-sm text-slate-500"
  >
  By continuing, you agree to our{' '}
  <button className="text-indigo-600 hover:text-indigo-700 transition-colors underline">
  Terms of Service
  </button>{' '}
  and{' '}
  <button className="text-indigo-600 hover:text-indigo-700 transition-colors underline">
  Privacy Policy
  </button>
  </motion.div>
  </div>

  {/* Subtle overlay for depth */}
  <div className="absolute inset-0 bg-gradient-to-t from-white/5 via-transparent to-white/10 pointer-events-none" />
  </div>
  );
}