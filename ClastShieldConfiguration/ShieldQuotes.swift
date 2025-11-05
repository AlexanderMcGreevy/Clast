import Foundation

/*
 ShieldQuotes - Motivational Quote Pool

 Provides random quotes about:
 - Phone addiction awareness
 - Focus and productivity
 - General motivation
 - Digital wellbeing

 Usage:
   let quote = ShieldQuotes.randomQuote()
   print(quote.text)
   print(quote.author)
*/

struct Quote {
    let text: String
    let author: String?

    var formatted: String {
        if let author = author {
            return "\"\(text)\"\n– \(author)"
        } else {
            return text
        }
    }
}

enum ShieldQuotes {
    // MARK: - Quote Collections

    private static let phoneAddictionQuotes = [
        Quote(text: "The average person checks their phone 96 times per day. That's once every 10 minutes.", author: nil),
        Quote(text: "You are not addicted to your phone. You're addicted to the feeling of connection it provides.", author: nil),
        Quote(text: "Every notification is designed to steal your attention. Take it back.", author: nil),
        Quote(text: "Your phone is a tool. Don't let it use you.", author: nil),
        Quote(text: "Studies show it takes 23 minutes to refocus after a distraction. Protect your attention.", author: nil),
        Quote(text: "The cost of a thing is the amount of life you exchange for it.", author: "Henry David Thoreau"),
        Quote(text: "What you feed your mind becomes your reality. Choose wisely.", author: nil),
        Quote(text: "You can't buy back time. Spend it intentionally.", author: nil),
        Quote(text: "Every time you unlock your phone, ask: Is this what I want to be doing right now?", author: nil),
        Quote(text: "Deep work is rare, valuable, and meaningful. Shallow work is easy and forgettable.", author: "Cal Newport"),
    ]

    private static let focusQuotes = [
        Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
        Quote(text: "Focus is a matter of deciding what things you're not going to do.", author: "John Carmack"),
        Quote(text: "The secret of change is to focus all of your energy not on fighting the old, but on building the new.", author: "Socrates"),
        Quote(text: "Concentrate all your thoughts upon the work in hand. The sun's rays do not burn until brought to a focus.", author: "Alexander Graham Bell"),
        Quote(text: "It's not always that we need to do more but rather that we need to focus on less.", author: "Nathan W. Morris"),
        Quote(text: "Where focus goes, energy flows.", author: "Tony Robbins"),
        Quote(text: "The successful warrior is the average man, with laser-like focus.", author: "Bruce Lee"),
        Quote(text: "Your focus determines your reality.", author: "George Lucas"),
        Quote(text: "Focus on being productive instead of busy.", author: "Tim Ferriss"),
        Quote(text: "Starve your distractions, feed your focus.", author: nil),
    ]

    private static let motivationQuotes = [
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
        Quote(text: "The harder you work for something, the greater you'll feel when you achieve it.", author: nil),
        Quote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
        Quote(text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar"),
        Quote(text: "The only limit to our realization of tomorrow will be our doubts of today.", author: "Franklin D. Roosevelt"),
        Quote(text: "What we fear doing most is usually what we most need to do.", author: "Tim Ferriss"),
        Quote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
        Quote(text: "You are what you do, not what you say you'll do.", author: "Carl Jung"),
        Quote(text: "Small daily improvements over time lead to stunning results.", author: nil),
    ]

    private static let mindfulnessQuotes = [
        Quote(text: "The present moment is the only time over which we have dominion.", author: "Thích Nhất Hạnh"),
        Quote(text: "Almost everything will work again if you unplug it for a few minutes, including you.", author: "Anne Lamott"),
        Quote(text: "You can't stop the waves, but you can learn to surf.", author: "Jon Kabat-Zinn"),
        Quote(text: "The quieter you become, the more you can hear.", author: "Ram Dass"),
        Quote(text: "Be happy in the moment, that's enough. Each moment is all we need, not more.", author: "Mother Teresa"),
        Quote(text: "Wherever you are, be all there.", author: "Jim Elliot"),
        Quote(text: "In today's rush, we all think too much, seek too much, want too much and forget about the joy of just being.", author: "Eckhart Tolle"),
        Quote(text: "The best way to capture moments is to pay attention. This is how we cultivate mindfulness.", author: "Jon Kabat-Zinn"),
        Quote(text: "Doing less is not being lazy. Don't give in to a culture that values personal sacrifice over personal productivity.", author: "Tim Ferriss"),
        Quote(text: "Sometimes the most productive thing you can do is relax.", author: "Mark Black"),
    ]

    private static let digitalWellbeingQuotes = [
        Quote(text: "Technology is a useful servant but a dangerous master.", author: "Christian Lous Lange"),
        Quote(text: "We are drowning in information but starved for knowledge.", author: "John Naisbitt"),
        Quote(text: "The cost of distraction is high. The reward for focus is immeasurable.", author: nil),
        Quote(text: "Your smartphone is making you stupid, antisocial, and unhealthy. So why can't you put it down?", author: "Jean Twenge"),
        Quote(text: "Comparison is the thief of joy.", author: "Theodore Roosevelt"),
        Quote(text: "Real life is in front of you, not on a screen.", author: nil),
        Quote(text: "The best moment is now. Not later, not tomorrow. Right now.", author: nil),
        Quote(text: "Choose experiences over scrolling. Choose presence over pixels.", author: nil),
        Quote(text: "Your life is happening right now. Don't miss it while you're looking at a screen.", author: nil),
        Quote(text: "Delete the app. Keep the memory.", author: nil),
    ]

    // MARK: - All Quotes Combined

    private static let allQuotes = phoneAddictionQuotes + focusQuotes + motivationQuotes + mindfulnessQuotes + digitalWellbeingQuotes

    // MARK: - Public API

    /// Get a random quote from the entire pool
    static func randomQuote() -> Quote {
        allQuotes.randomElement() ?? Quote(text: "Stay focused. Build something amazing.", author: nil)
    }

    /// Get a random quote from a specific category
    static func randomQuote(from category: QuoteCategory) -> Quote {
        let quotes: [Quote]
        switch category {
        case .phoneAddiction:
            quotes = phoneAddictionQuotes
        case .focus:
            quotes = focusQuotes
        case .motivation:
            quotes = motivationQuotes
        case .mindfulness:
            quotes = mindfulnessQuotes
        case .digitalWellbeing:
            quotes = digitalWellbeingQuotes
        }
        return quotes.randomElement() ?? Quote(text: "Stay focused.", author: nil)
    }

    enum QuoteCategory {
        case phoneAddiction
        case focus
        case motivation
        case mindfulness
        case digitalWellbeing
    }
}
