export function InteractPrompt({ text }: { text: string }) {
  return (
    <div className="absolute bottom-6 left-1/2 -translate-x-1/2 rounded-full bg-black/60 px-4 py-1 text-white">
      {text}
    </div>
  )
}
