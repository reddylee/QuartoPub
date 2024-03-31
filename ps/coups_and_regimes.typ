// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
#show: doc => article(
  title: [How Regime Types Affect the Likelihood of Coups],
  authors: (
    ( name: [Zhu Qi],
      affiliation: [University of Essex],
      email: [qz21485\@essex.ac.uk] ),
    ),
  date: [2024-03-29],
  abstract: [#strong[Abstract:] A substantial body of research has examined coups, with much of it focusing on the factors that lead to coup attempts. However, consensus remains elusive regarding why coups are more prevalent in certain countries while less so in others. Previous scholarship exploring the determinants of coup attempts has often overlooked the crucial aspect of coup success. Given the severe consequences of a failed coup, coup plotters are unlikely to proceed unless they perceive a high probability of success. Thus, the outcome of a coup—whether successful or unsuccessful—is not merely incidental but serves as a pivotal determinant of coup attempts. The decision to stage a coup is a self-selected variable contingent upon the anticipated success rate of coups. This study employs a sample selection model \(specifically, a two-stage probit model) to elucidate why coups are more common in some autocratic countries but rare in others. I contend that coup attempts are largely shaped by the likelihood of coup success, which, in turn, hinges on the power dynamics between coup perpetrators and incumbents. These power dynamics are influenced by the regime type and their distinct responses to internal and external shocks.

],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


= Introduction
<introduction>
Coups#footnote[Coups, according to Powell and Thyne, are "illegal and overt attempts by the military or other elites within the state apparatus to unseat the sitting executive" #cite(<powell2011>)[, p.~252];.] are more frequently in some countries but rarely in others. According to Global Instances of Coups #cite(<powell2011>)[, hereinafter GIC];, in Latin America, coups occurred 23 times in Bolivia from 1950 to 1984, and 20 times in Argentina in almost the same period. In Mexico’s authoritarian period from 1917 to 2000, however, no coup occurred at all. In Africa, Sudan encountered 17 coups from 1955 to 2021, while no coup occurred in South Africa since 1950. Similar stories happened in the Middle East and south Asia. Previous studies have tried to explain these disparities from different perspectives. "About one hundred potential determinants of coups have been proposed, but no consensus has emerged on an established baseline model for analyzing coups" #cite(<gassebner2016a>);. The question remains unanswered.

To analyse determinants of coups, the most important characteristic of coups should not be overlooked. Coups are #strong[illegal] attempts against the current leaders and the cost of failed coups could be too expensive to bear. Perpetrators of coups might be put to jail, forced to exile, or even sentenced to death if they fail. Sometimes even worse, the punishment might fall on the perpetrators’ family. Although staging coups is so risky, there were still many coups occurred-484 coups have been launched since 1950 \(GIC). In 2021, 7 coups occurred in 6 countries, the most frequent year since 2000#footnote[Myanmar \(February, succeeded), Niger \(March, failed), Chad \(April, succeeded), Mali \(May, succeeded), Guinea \(September, succeeded), and Sudan \(September, failed; October, succeeded).];.

To understand the logic of perpetrators of coups, we need to analyse the pay-offs of coups. When a coup is launched, the perpetrators expect to earn something from the coup, not to lose, which depends on how likely they will succeed. Therefore, when coup plotters plan to stage a coup, the first and foremost thing they will consider is their likelihood of success. They might have many incentives to launch a coup, but they are less likely to put the plot into practice without some certainty of success. When the chances of success are low, coup plotters either abort their schemes or wait for better timing. It is hard to know the threshold of chances of success, but previous coups show that the success rates of staged coups are quite satisfactory \(Table ). The most recent coups staged in 2021, with 5 successful coups out of 7 staged coups, show an even higher success rate.

== References
<references>



#bibliography("references.bib")

