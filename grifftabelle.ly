\version "2.24"

#(set! paper-alist (cons '("a5l" . (cons (* 297 mm) (* 210 mm))) paper-alist))
\paper {
	#(set-paper-size "a5l" )

	top-margin = 7
	bottom-margin = 0
	left-margin = 0
	right-margin = 5

    oddFooterMarkup = ""
}



% settings to be applied to all staffs
\layout {

  indent = 1\cm

  \context {
  % reduce space between staffs in a StaffGroup
  \StaffGroup
    % affects the spacings, except the last staff, so a hidden dummy was added
    \override StaffGrouper.staff-staff-spacing.padding = #10

  }
  \context {
    \Staff
    
    % no "C" at the beginning of the line
    \override TimeSignature.stencil = ##f
    % make everything smaller
    \magnifyStaff #5/6

    measureBarType = "-span|"

    % right-align instrument names
    \override InstrumentName.self-alignment-X = #1

    % different clefs for different voices in the same staff
    \accepts "PseudoStaff"
  }
  \context {
    \name "PseudoStaff"
    \type Engraver_group
    \alias "Staff"
    \consists "Clef_engraver"
    \clef treble % Anything odd, just to mask clef changes in superior staff
    \override Clef.font-size = #-3
  }
}

% naturalize pitch, e.g., fes -> e
#(define (naturalize-pitch p)
(let ((o (ly:pitch-octave p))
(a (* 4 (ly:pitch-alteration p)))
;; alteration, a, in quarter tone steps,
;; for historical reasons
(n (ly:pitch-notename p)))
(cond
((and (> a 1) (or (eqv? n 6) (eqv? n 2)))
(set! a (- a 2))
(set! n (+ n 1)))
((and (< a -1) (or (eqv? n 0) (eqv? n 3)))
(set! a (+ a 2))
(set! n (- n 1))))
(cond
((> a 0) (set! a (- a 4)) (set! n (+ n 1)))
((< a -2) (set! a (+ a 4)) (set! n (- n 1))))
(if (< n 0) (begin (set! o (- o 1)) (set! n (+ n 7))))
(if (> n 6) (begin (set! o (+ o 1)) (set! n (- n 7))))
(ly:make-pitch o n (/ a 4))))

#(define (naturalize music)
(let ((es (ly:music-property music 'elements))
(e (ly:music-property music 'element))
(p (ly:music-property music 'pitch)))
(if (pair? es)
(ly:music-set-property!
music 'elements
(map naturalize es)))
(if (ly:music? e)
(ly:music-set-property!
music 'element
(naturalize e)))
(if (ly:pitch? p)
(begin
(set! p (naturalize-pitch p))
(ly:music-set-property! music 'pitch p)))
music))

naturalizeMusic =
#(define-music-function (m)
(ly:music?)
(naturalize m))

% natural pitch, see lilypond doc
part = \absolute { \omit Stem 
    c4_\markup { \finger { 0 } }
    b,_\markup { \finger { 2 } }
    bes,_\markup { \finger { 1 } }
    a,_\markup { \finger { 12 } }
    as,_\markup { \finger { 23 } }
    g,_\markup { \finger { 4 } }
    ges,_\markup { \finger { 24 } } 
    f,_\markup { \finger { 14 } } 
    e,_\markup { \finger { 124 } } 
    es,_\markup { \finger { 234 } } 
    d,_\markup { \finger { 134 } } 
    des,_\markup { \finger { 1234 } } 
} 

leiter =
#(define-music-function (pitch) (ly:pitch?)
   #{
     \new PseudoStaff = "ps" { \once \omit Clef  }
     <<
       \new Voice {
         \voiceTwo
         \naturalizeMusic \transpose c $pitch { \part }
       }
       \new Voice {
         \override NoteHead.color = #(rgb-color 0.5 0.5 1)
         \override Accidental.color = #(rgb-color 0.5 0.5 1)
         \voiceOne
         \override TextScript.stencil = ##f
         % each voice treats their accidentals independently
         \accidentalStyle voice
         % change clef of this voice (necessary to get the correct accidentals)
         \change Staff = "ps"
         \naturalizeMusic \transpose bes c'''
            { \transpose c $pitch { \part } }
       }
     >>
   #})

shift =
#(define-music-function (n) (number?)
   #{
\repeat unfold $n { s4 }
   #})

% pitches are way off
deviation = {
    \override TextScript.color = #(rgb-color 0.75 0.75 0.75)
    \override StaffSymbol.color = #(rgb-color 0.75 0.75 0.75)
}


\markup {
    \overlay {
    \translate #'(120 . 90) {\column { \left-align {
            \halign #-1
        \line {\huge "Grifftabelle B-Tuba"}
        \line {"(Version von Thomas Rebele)"}
        
        \vspace #1
        \line {
            \score { \new Staff \with {  } { \omit Stem \clef bass bes, } }
            "Bassschlüssel in C"
        }

        \vspace #1
        \line {
            \score { \new Staff \with { \override Clef.transparent=##t } { \omit Stem
                \override NoteHead.color = #(rgb-color 0.5 0.5 1) c'' 
                \override Staff.Clef.transparent=##f \override Staff.Clef.color = #(rgb-color 0.5 0.5 1) \clef treble  } }
            "Violinschlüssel in B"
        }

        \vspace #1
        \line {
            \score { \new Staff \with { \deviation } { \clef bass s1 } }
            "Töne haben zu viel Abweichung"
        }
    }}}

\score {
\new StaffGroup \with {   
    \override SystemStartBracket.stencil = ##f 
  \override SystemStartBar.stencil = ##f
    }
  <<
    \new Staff = "L0" \with { instrumentName = "0. " \magnifyStaff #2/3 } {
\override Score.SpacingSpanner.spacing-increment = #2.2
      \cadenzaOn
      \clef bass
      <>_"Pedaltöne"
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2 \shift 3 \shift 3 \shift 4 \shift 5 \shift 7
      \leiter  bes,,,

      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L1" \with { alignAboveContext = "L0" instrumentName = "1. "  } {
      \cadenzaOn
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2 \shift 3 \shift 3 \shift 4 \shift 5 \shift 7
      \bar "|"
      \leiter  bes,,
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L2" \with { alignAboveContext = "L1" instrumentName = "2. "  } {
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2 \shift 3 \shift 3 \shift 4 \shift 5
      \leiter f,
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L3" \with { alignAboveContext = "L2" instrumentName = "3. "  } {
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2 \shift 3 \shift 3\shift 4
      \bar "|"
      \leiter bes,
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L4" \with { alignAboveContext = "L3" instrumentName = "4. "  } {
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2 \shift 3 \shift 3
      \leiter d
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L5" \with { alignAboveContext = "L4" instrumentName = "5. "  } {
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2 \shift 3
      \leiter f
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L6" \with { alignAboveContext = "L5" instrumentName = "6. "  \deviation  \magnifyStaff #2/3 } {
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 \shift 2
      \leiter as
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L7" \with { alignAboveContext = "L6" instrumentName = "7. "  } {
      \clef bass
      \shift 1 \shift 2 \shift 2 \shift 2 
      \bar "|"
      \leiter bes
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L8" \with { alignAboveContext = "L7" instrumentName = "8. "  } {
      \clef bass
      \shift 1 \shift 2 \shift 2 
      \leiter c'
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L9" \with { alignAboveContext = "L8" instrumentName = "9. "  } {
      \clef bass
      \shift 1 \shift 2
      \leiter d'
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L10" \with { alignAboveContext = "L9" instrumentName = "10. "  \deviation \magnifyStaff #2/3 } {
      \clef bass
      \shift 1
      \leiter e'
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }
    \new Staff = "L11" \with { alignAboveContext = "L10" instrumentName = "11. " } {
      \clef bass
      \leiter f'
      \override Staff.Clef.color = #(rgb-color 0.5 0.5 1)
      \clef treble
    }

    % hidden dummy to get the spacing right
    \new Staff = "dummy" \with { alignAboveContext = "L11" instrumentName = ""
  \override StaffSymbol.stencil = ##f
  \override BarLine.stencil = ##f
  \override TimeSignature.stencil = ##f
  \override KeySignature.stencil = ##f
  \override Clef.stencil = ##f
  \override NoteHead.stencil = ##f
  \override Stem.stencil = ##f
  \override Beam.stencil = ##f
  \override Flag.stencil = ##f
  \override Rest.stencil = ##f
  \override Tie.stencil = ##f
  \override Slur.stencil = ##f
  \override Script.stencil = ##f

    } {
      s1
    }
  >>
  
}


}
}


