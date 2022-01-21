
# wsolve

## Bash script solver of Wordle puzzles
This little project seeks to solve [Wordle puzzles](https://powerlanguage.co.uk/wordle) by making use of regular expressions and an input file that contains lots and lots of words.

## The tech
This was primarily an exercise in [bash](https://www.gnu.org/software/bash/) script writing. Secondly, it was an exercise in leveraging [Regular Expressions](https://en.wikipedia.org/wiki/Regular_expression) but specifically doing so via the use of [grep](https://en.wikipedia.org/wiki/Grep) - which has its idiosyncrasies. I am fairly well versed in the use of *RegEx* but not *grep* so much, so this was an opportunity to get some practice on the latter.

## The algorithm
The algorithm is fairly simple.

1. Start by guessing a random word - well, not random at all really. It
    always starts with the word *"adieu"* which contains four vowels and
    a common consonant. The theory is that the letters identified as
    incorrect from these five will narrow down subsequent choices more
    significantly than less common letters.

2. Read answer to guessed word from user.
	*- Exit Condition: if all letters are positionally correct, exit with message that puzzle was solved.*
3. Once an answer is received for the word, construct four regular expressions to whittle down the list of words with:
	- **Valid letters:** Regex to match all words which contain the letters identified as valid; If a word does not contain all the valid letters from the previous guess(es), then it is clearly not a candidate and is removed from the base list.
	*Note: This RegEx makes use of positive lookahead which is supported by grep only as Perl compatible regular expressions (PCRE). As such, the grep command that uses this RegEx is invoked with the -P flag*
	- **Invalid letters:** Regex to match all words which contain none of the letters identified as invalid; If a word contains any of the invalid letters from the previous guess(es), then it is clearly not a candidate and is removed from the base list.
	- **Positionally correct letters:** RegEx to match all words which contain the positionally correct letters in the correct character position.
	- **Positionally incorrect letters:** RegEx to match all words which do not contain a valid letter in a known incorrect character position.
4. Use *grep* to match these four *regular expressions* against the base list of words and so whittle it down to a smaller list.
5. Pick the first word from the remaining list and repeat from step 2.
	*- Exit Condition: if no words remain, exit with message indicating that a solution was not found*

 

## Does it work?
Yes. Mostly. The script obviously relies on a good quality base list of words. So far it has solved every Wordle I've tested it on but I can easily see how it will fail some.

The way the algorithm picks a subsequent guess is simply to take the first word from the remaining list of candidate words. This choice can be improved by using a word list sorted by decreasing word frequency - such as the one obtained from https://github.com/first20hours/google-10000-english

However, there is big room for improvement here. It would be much better to pick a word from the remaining candidates that has the most overlap with other words from the list. One method for doing this would be to calculate the collective [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) between each word and all other words, and then picking the word with the lowest total Levenshtein distance. This would have been an easy task in Go or C# but I specifically wanted to do this as a bash script for the practice I'd get.

I also discovered that the 20k most common words in the English language doesn't include some words I would've expected to be fairly common. One such recent find was the word 'prick' which is simply absent from the source list.

Another source list I've used is one obtained from https://github.com/dwyl/english-words. This one includes many more words but without the frequency sorting. Be prepared to guess words like 'ccitt' or 'jezdy' (or even Roman numerals like 'xxiii').

The search for an optimal source list continues. And if I can motivate myself, I might add a Levenshtein distance function to the algorithm at some point.

## Why?
I find myself very often having to trawl through enormous log files, looking for certain patterns or irregularities. Regular Expressions are very useful for that but I've often been frustrated by the trickery of grep. So I decided I'd use this an an opportunity to refine my knowledge of grep a little.
