// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

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

#show raw.where(block: true): set block(
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
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
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

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
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
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
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
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  pagenumbering: "1",
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
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
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
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
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [Power Dynamics and Autocoup Attempts],
  authors: (
    ( name: [Zhu Qi],
      affiliation: [University of Essex],
      email: [qz21485\@essex.ac.uk] ),
    ),
  date: [2025-06-19],
  abstract: [This chapter explores the determinants of autocoup attempts, aiming to deepen understanding of the political dynamics that underpin tenure extensions by incumbent leaders. Addressing a notable gap in the existing literature, the study contends that the balance of power plays a critical role in shaping the likelihood of autocoup events. In contrast to classical coups---which are often triggered by unstable or fragmented power structures---autocoups tend to arise in contexts characterised by stable and concentrated power. To operationalise the concept of power balance in an observable manner, regime type is employed as a proxy, reflecting the structural distribution of power between incumbents and potential institutional constraints or elite challengers. Using a bias-reduced logistic regression model, the analysis finds that regime type is a significant predictor of autocoup attempts. Leaders operating within regimes marked by concentrated power are more prone to extend their tenure unconstitutionally. In particular, presidential democracies and personalist autocracies are found to be significantly more susceptible to autocoup attempts than dominant-party regimes. The study contributes to the broader literature on irregular leadership transitions by offering a more systematic and empirically grounded account of the conditions under which incumbents seek to subvert constitutional term limits.

],
  abstract-title: "Abstract",
  font: ("Times New Roman",),
  fontsize: 12pt,
  sectionnumbering: "1.1.a",
  pagenumbering: "1",
  toc: true,
  toc_title: [Contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Introduction
<introduction>
As outlined in Chapter 2, scholarly engagement with autocoups has been hampered by conceptual ambiguity and the absence of systematic data, thereby limiting the scope for rigorous empirical investigation. To address this lacuna, the present chapter aims to make a substantive contribution through a quantitative analysis of the determinants of autocoup attempts. Following the methodological precedent established by empirical studies of classical coups---which have primarily examined the antecedents of coup initiation @gassebner2016---this chapter similarly explores why some incumbent leaders attempt to extend their tenure through autocoups, while others do not.

There are three principal reasons for investigating the determinants of autocoups. First, autocoups constitute one of the most prevalent forms of irregular leadership transition, with over 80 documented cases since 1945 (as discussed in Chapter 2). Their frequency has increased notably since 2000, coinciding with a marked global decline in classical coups @bermeo2016@thyne2019. Second, autocoups exert profound effects on political stability and democratic development, often resulting in enduring institutional degradation. Third, identifying the drivers of autocoup attempts is essential for future research into their consequences; without a clear understanding of the conditions under which autocoups occur, efforts to prevent them or mitigate their detrimental effects remain constrained.

Although autocoups differ fundamentally from classical coups---particularly in that they are instigated by incumbents rather than external challengers---the two phenomena share key features as disruptions to established political order. Accordingly, methodological tools commonly applied in the study of traditional coups may be fruitfully adapted to analyse autocoups. However, despite the extensive literature on coup dynamics @gassebner2016, regime type is frequently treated as a background condition or control variable rather than a central explanatory factor.

This chapter advances the argument that the likelihood of autocoup attempts is shaped significantly by the structural distribution of power inherent in regime type. In contrast to classical coups, which often emerge from unstable or contested power structures, autocoups tend to occur in regimes characterised by concentrated and stable authority. Given the challenges of directly measuring internal power configurations, regime type is employed as a proxy variable. The underlying premise is that regime type reflects core institutional arrangements, including the distribution of authority, the robustness of constitutional constraints, and the capacity of incumbents to subvert democratic norms. Analysing cross-regime variation thus facilitates a deeper understanding of the institutional foundations that condition autocoup risk. These power structures tend to be relatively stable over time, as they both shape and are shaped by the regime's overarching institutional design @geddes2014.

To empirically test this proposition, the chapter utilises both a standard logistic regression model and a bias-reduced logistic regression model to assess how regime type influences the likelihood of incumbents extending their tenure through extra-constitutional means.

Given the paucity of quantitative research on autocoups, this study offers a potentially pioneering contribution to the empirical literature by providing a theoretically informed and methodologically rigorous account of their determinants.

The remainder of the chapter is structured as follows. Section 2 examines the dynamics and outcomes of autocoup attempts. Section 3 outlines the research design, including the methodological approach and variables employed. Section 4 presents and interprets the empirical findings, highlighting key patterns and implications. Section 5 concludes by summarising the core insights and reflecting on their broader significance for understanding and mitigating the risks posed by autocoups.

= Dynamics of autocoup attempts
<dynamics-of-autocoup-attempts>
Like traditional coup attempts, autocoups are shaped by two fundamental elements: the disposition of incumbent leaders---referring to their motivations and willingness to act---and their capability, defined by the resources and opportunities at their disposal. However, autocoups exhibit two notable features that distinguish them from classical coups. First, whereas traditional coups occur predominantly in autocracies @thyne2014, over one-third of documented autocoups have taken place in democratic regimes, as outlined in Chapter 2. Second, while the success rate of traditional coups hovers around $50 %$, more than $77 %$ of autocoup attempts have resulted in success, according to the dataset introduced in Chapter 2. These distinctions indicate that the dynamics of disposition and capability underlying autocoups differ significantly from those of traditional coups.

This section explores the complex dynamics of autocoup attempts, with particular emphasis on how the motivations of incumbents, the determinants of success, and the institutional frameworks of various regime types shape the vulnerability of states to such extra-constitutional power extensions.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Motivations for autocoups
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Motivations for autocoups
]
)
]
Incumbents seeking to prolong their tenure may be driven by a range of motivations, broadly falling into three principal categories: personal ambition, appeals to national interest, and self-preservation.

First, the pursuit of personal power constitutes a compelling incentive for many leaders. The capacity to govern free from institutional constraints enables incumbents to exercise dominance over national policy-making, access state resources, influence the judiciary and legislature, and retain the prestige associated with holding high office. For some, the aspiration to secure a lasting political legacy---to be remembered as a transformative figure---further amplifies the appeal of extended rule.

Second, tenure extensions are often justified by incumbents in the name of the national interest. A commonly advanced rationale suggests that a single term is insufficient for the completion of long-term reforms or development initiatives. Within this narrative, remaining in power is portrayed as essential to ensuring the continuity and success of ongoing projects. The autocoup is thus framed not as an act of self-interest, but as a necessary step for the greater good.

Third, autocoups may serve as mechanisms of self-preservation. Incumbents facing the prospect of prosecution for corruption, human rights violations, or other transgressions may view continued tenure as a means of preserving legal immunity. Additionally, those who have amassed significant political adversaries during their rule may fear retribution upon leaving office. In such cases, the extension of power is not merely a product of ambition but also a strategy for survival---intended to shield the leader from legal or political repercussions.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Power dynamics and autocoups
]
)
]
While motivations may initiate an incumbent's decision to pursue an autocoup, the decisive factor often lies in their ability to implement and sustain such an action. The relatively high frequency and remarkable success rate of autocoups---over $77 %$, compared to approximately $50 %$ for classical coups---suggest that incumbents benefit from notable structural advantages when attempting to consolidate power. These advantages are not limited to autocracies but are also evident in democratic systems, underscoring the variation in institutional leverage available to incumbents across different regime types.

This reality necessitates a closer examination of state power structures, particularly the allocation of control over the military. The allegiance of the armed forces is a critical determinant of autocoup outcomes. If the military remains loyal to the executive, resistance---whether from civil society, the judiciary, or the legislature---can be suppressed or marginalised. Conversely, open defiance or refusal by the military to support the incumbent may render an autocoup untenable.

Nevertheless, it is reductive to assume that formal authority as commander-in-chief guarantees unqualified control. Just as it is overly simplistic to attribute the success of traditional coups solely to the presence of military force @singh2016, it is equally erroneous to presume that incumbents invariably enjoy the unconditional loyalty of the armed forces. Nominal titles often obscure the complex and sometimes precarious dynamics underpinning military allegiance.

In autocratic regimes, while the military may not be bound by constitutional principles, it is not inherently loyal to the head of state. Executives depend on military officers to execute their commands; however, these officers may harbour independent political ambitions or competing loyalties. A case in point is Uganda in 1971, when President Milton Obote attempted to dismiss General Idi Amin. In response, Amin exploited his influence within the armed forces to mount a successful coup, ousting Obote @sudduth2017.

By contrast, in consolidated democracies, military loyalty is typically institutionalised through allegiance to the constitution rather than to individual officeholders. For example, in the United States, following the 2020 presidential election, General Mark Milley, Chairman of the Joint Chiefs of Staff, publicly reaffirmed the military's constitutional commitment: "We are unique among militaries. We do not take an oath to a king or a queen, a tyrant or a dictator. We do not take an oath to an individual. We take an oath to the Constitution." (US Army Museum, 12 November 2020\[^1\])

In hybrid regimes or fragile democracies, attempts to prolong executive tenure may entail significant political risks. In Niger, for example, President Mamadou Tandja's attempt in 2009 to amend the constitution to permit a third term precipitated a military coup in 2010 @miller2016. Similarly, in Honduras the same year, President Manuel Zelaya was removed from office by the military after seeking to alter the constitution to allow immediate re-election @muñoz-portillo2019.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Regime types and autocoups
]
)
]
Given the complexities discussed, a more effective analytical strategy entails evaluating the broader balance of power within political systems. As direct observation of this balance is inherently challenging, this study adopts regime type as a proxy---an approach consistent with established methodologies in comparative politics. Regime types encapsulate the institutional architecture of power distribution, particularly with respect to control over the military, political appointments, and policy-making authority.

Following the typology developed by #cite(<geddes2014>, form: "prose");, autocratic regimes can be categorised as follows:

#strong[Military regimes] are governed by a junta, typically comprising senior military officers who collectively determine leadership and policy direction. Notable examples include Brazil (1964--1985), Argentina (1976--1983), and El Salvador (1948--1984) @geddes1999.

#strong[Personalist regimes] revolve around a dominant individual who wields unchecked authority over the military, policy decisions, and succession processes. Prominent instances include Rafael Trujillo in the Dominican Republic (1930--1961), Idi Amin in Uganda (1971--1979), and Jean-Bédel Bokassa in the Central African Republic (1966--1979) @geddes1999.

#strong[Dominant-party regimes] concentrate authority within a structured political party, with the leader operating either as part of or at the helm of the party apparatus. Illustrative cases include the PRI in Mexico, CCM in Tanzania, and the Leninist parties of Eastern Europe @geddes1999.

Among these regime types, personalist autocracies are particularly conducive to autocoups. The concentration of power in a single individual weakens institutional checks and fosters loyalty---particularly from the military---through mechanisms of personal patronage. While military regimes are rooted in coercive power, they are often beset by internal factionalism, rendering them more susceptible to traditional coups than to autocoups. Dominant-party regimes occupy a more ambiguous position: although party structures can constrain executive action, exceptionally powerful party leaders may still initiate autocoups, as exemplified by Xi Jinping's constitutional amendments in 2018 within a dominant-party framework.

Monarchies, though technically autocratic, generally render autocoups redundant, as monarchs typically rule for life by constitutional design.

A key clarification is warranted at this juncture: why might leaders in personalist regimes---already possessing extensive authority---feel compelled to extend their tenure further? The answer lies in distinguishing between the scope and duration of power. While such leaders may exercise considerable de facto control over state institutions, many initially assume office via legal or constitutional channels, necessitating a gradual process of consolidation. In this context, autocoups function as formal mechanisms to institutionalise existing dominance---transforming informal power into legally sanctioned permanence. This dynamic is exemplified by the repeated tenure extensions pursued by Vladimir Putin and Alexander Lukashenko.

In post-Soviet Russia, President Boris Yeltsin presided over the transformation of a parliamentary system into a personalist regime. However, Yeltsin himself did not overstay his term; instead, he designated Vladimir Putin as his successor. Upon assuming office in 2000, Putin progressively entrenched his authority, employing constitutional amendments and legal strategies to circumvent term limits and extend his rule indefinitely.

Likewise, in Belarus, Alexander Lukashenko was elected president in 1994 under a party-based system. Within a year, he dismantled the existing institutional framework and established a personalist regime. Since then, he has remained in power through successive tenure extensions, steadily consolidating his control over the state apparatus.

In democratic contexts, autocoups are found exclusively in presidential systems. This reflects the institutional leverage enjoyed by presidents, who are directly elected, typically command the armed forces, and may possess the capacity to override or circumvent legislative opposition. By contrast, prime ministers in parliamentary systems are considerably more constrained. Their tenure depends on maintaining legislative confidence and they may be removed through votes of no confidence. Moreover, they often lack direct control over the military, which is institutionally separated from their office. As a result, prime ministers are subject to more frequent leadership turnover and face fewer opportunities to unilaterally extend their mandates. For instance, the United Kingdom saw three prime ministers serve in 2022 alone, while Japan has had 36 prime ministers since 1945---an average of one every two years. In contrast, only 14 presidents have served in the United States over the same period, reflecting greater institutional continuity. These structural distinctions render presidential systems more conducive to autocoups---even within well-established democracies---due to their centralised executive authority and command over the military.

From this analysis, the following hypothesis is proposed:

The likelihood of autocoup attempts is significantly shaped by regime type, with regimes characterised by concentrated and stable executive power---namely, personalist autocracies and presidential democracies---being the most susceptible, relative to other regime types.

#strong[#emph[H3-1: The likelihood of autocoup attempts is significantly shaped by regime type, with regimes characterised by concentrated and stable executive power---namely, personalist autocracies and presidential democracies---being the most susceptible, relative to other regime types.];]

= Research design
<research-design>
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Methodology
]
)
]
Given the binary nature of the dependent variable---namely, whether an autocoup is attempted in a given country-year---the study initially employs a logistic regression model to investigate the determinants of autocoup attempts. This method enables the identification of statistically significant factors influencing the likelihood of such events, as well as the direction and magnitude of their effects.

Nevertheless, the rarity of autocoup incidents---83 cases out of over 9,000 observations---poses a methodological challenge. Standard maximum likelihood estimation techniques, including conventional logit and probit models, are prone to underestimating the probability of rare events. To mitigate this limitation and improve the robustness of statistical inference, the analysis also employs Firth's Bias-Reduced Penalised Maximum Likelihood Estimation (commonly referred to as Bias-Reduced Logit), as outlined by #cite(<firth1993>, form: "prose");.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Data and variables
]
)
]
The primary dataset, which incorporates information on autocoups and regime types, spans the period from 1945 to 2023. However, due to data alignment limitations, the usable data range extends from 1945 to 2018. The dataset comprises approximately 9,400 country-year observations, of which 83 represent recorded autocoup attempts.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Dependent variable
]
)
]
The analysis draws upon the autocoup dataset introduced in Chapter 2, which covers the period from 1945 to 2023 and includes 83 documented autocoup attempts. Summary statistics for these events, as well as the corresponding regime classifications, are presented in Chapter 2.

#strong[Autocoup attempt];: A binary variable indicating whether an autocoup attempt occurred (coded as 1) or did not occur (coded as 0) in each country-year observation.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Independent variables
]
)
]
The principal independent variable in this analysis is regime type, reflecting the central analytical focus of the study. Regime classifications are drawn from the typology developed by #cite(<geddes2014>, form: "prose") (GWF dataset), which distinguishes among military, personalist, and dominant-party regimes within autocratic systems. For democratic systems, regimes are categorised as either parliamentary or presidential. A residual category---labelled "other"---captures regimes that are provisional, transitional, or otherwise not easily classified within the primary typology.

In addition to regime type, a range of control variables is included, selected on the basis of established scholarship on the determinants of coups. These controls account for factors such as economic performance, political violence, and the tenure of incumbents. Further controls comprise the level of democracy, population size, and a Cold War dummy variable, which captures temporal variation in the global political environment.

#strong[Economic Level:] Measured by GDP per capita, this variable reflects the overall economic wellbeing of a country. Data are sourced from the V-Dem dataset @fariss2022 and are expressed in constant 2017 international dollars (PPP, per thousand).

#strong[Economic Performance:] Operationalised via the Current-Trend (CT) ratio developed by #cite(<krishnarajan2019>, form: "prose");, this measure compares current GDP per capita with the average of the previous five years. Higher CT values indicate stronger economic growth. Formally:

\$\$
    \\begin{aligned}
    CT\_{i,t} = {GDP/cap\_{i,t} \\over {1 \\over 5} {\\sum\_{k=1}^5GDP/cap\_{i,t-k}}}
    \\end{aligned}
\$\$

#strong[Political violence:] Measured using a violence index based on the "actotal" variable from the Major Episodes of Political Violence dataset @marshall2005current, this index captures both internal and interstate conflict. Scores range from 0 (complete stability) to 18 (maximum instability).

#strong[Days in office (log):] The natural logarithm of an incumbent leader's cumulative days in office is included as a proxy for power consolidation. Longer tenures are hypothesised to facilitate the conditions necessary for an autocoup. Data are drawn from the Archigos dataset @goemans2009 and the Political Leaders' Affiliation Database (PLAD) @bomprezzi2024wedded.

#strong[Democratic level:] This variable employs the Polity V score to measure the degree of democracy in a country, ranging from -10 (fully autocratic) to +10 (fully democratic). The index, developed by the Centre for Systemic Peace, assesses regime characteristics such as the competitiveness of political participation, executive recruitment, and constraints on executive authority @marshall2005current.

#strong[Population size:] The natural logarithm of a country's population is included to account for the potential effects of demographic scale on governance. Larger populations may present more complex administrative challenges and generate greater opposition. Data are sourced from the V-Dem dataset.

#strong[Cold War:] Following the precedent of earlier studies @thyne2014@derpanopoulos2016@dahl2023, a dummy variable is included to distinguish the Cold War period (approximately 1960--1990) from the post-Cold War era. This distinction reflects the relative paucity of autocoup events during the Cold War and their increased frequency thereafter.

= Results and discussion
<results-and-discussion>
This chapter employs logistic regression techniques to examine the structural and contextual factors that influence the probability of autocoup attempts. Given the dichotomous nature of the dependent variable---whether or not an autocoup attempt occurred in a specific country-year---and the rarity of such events (78 out of 9,434 observations) in certain categories, the analysis includes both a standard logit model and a bias-reduced logit model. The latter is particularly well-suited for rare events data, as it corrects for the small-sample bias often encountered with conventional maximum likelihood estimation. Consequently, the interpretation of results prioritises estimates from the bias-reduced model. Odds Ratios (ORs) are reported to facilitate an intuitive understanding of effect sizes.

#ref(<tbl-autocoupmodel>, supplement: [Table]) presents the model estimates. The core hypothesis posits that regime type is a key predictor of autocoup incidence, particularly that personalist regimes and presidential democracies are significantly more prone to such events than dominant-party regimes, which serve as the reference category.

#figure([
], caption: figure.caption(
position: top, 
[
Determinants of Autocoup Attempts(1945-2018)
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-autocoupmodel>


The empirical results provide robust support for this hypothesis. In the bias-reduced model, the odds of an autocoup occurring in a personalist regime are more than twice as high as in a dominant-party regime (OR = 2.08, p \< 0.05). In presidential democracies, the odds are nearly five times greater (OR = 4.87, p \< 0.01). To illustrate the magnitude of these effects, I compute predicted probabilities for a prototypical country in the dataset, holding all other covariates at their mean values. In dominant-party regimes, the predicted probability of an autocoup in a given year is approximately $0.99 %$. In personalist regimes, the probability rises to around $2.0 %$. In presidential democracies, the likelihood increases further to approximately $4.7 %$. While these probabilities are low in absolute terms---reflecting the rarity of autocoup events---the relative differences are substantial. Leaders in presidential democracies, for instance, are nearly five times more likely to attempt an autocoup than those in dominant-party systems, holding other factors constant. This underscores the structural vulnerability of executive-centric political systems, particularly when institutional checks on executive power are weak.

Among other regime types, military and parliamentary democracies do not show statistically significant differences in autocoup likelihood relative to dominant-party regimes. The residual "other" category does reach marginal significance (OR = 0.34, p \< 0.1), suggesting lower odds, although the heterogeneity within this group warrants cautious interpretation.

Turning to the control variables, several findings warrant closer attention. The Polity V score, which proxies the level of democratic institutionalisation, is significantly associated with reduced odds of autocoup (OR = 0.91, p \< 0.01). Substantively, this indicates that for each one-point increase in Polity score, the odds of an autocoup decrease by approximately $9 %$, holding other factors constant. This underscores the protective role of democratic institutions against executive overreach.

The Cold War indicator also emerges as significant (OR = 0.45, p \< 0.01), suggesting that autocoups were $55 %$ less likely during the Cold War era than in the post-Cold War period. This aligns with historical interpretations that view the Cold War as imposing external constraints on authoritarian innovation, often via superpower influence.

The analysis reveals a statistically significant, albeit marginal, negative relationship between the log of population size and the incidence of autocoups (OR = 0.86, p \< 0.1). This suggests that as a country's population grows, the odds of an autocoup tend to decrease. This finding aligns with theoretical arguments positing that larger, more populous states may exhibit greater organizational complexity and higher visibility of executive power dynamics, thereby increasing the difficulty and scrutiny associated with an executive power grab.

Conversely, indicators of economic performance---including GDP per capita, GDP growth, and political violence---do not exhibit statistically significant relationships with the outcome variable. Likewise, the log of days in office for the incumbent does not significantly predict autocoup attempts, suggesting that tenure alone is not a sufficient condition for extra-constitutional moves.

In sum, the analysis confirms that regime type---particularly personalist and presidential systems---is a critical structural condition influencing the likelihood of autocoup attempts. The inclusion of predicted probabilities and percentage changes in odds ratios serves to clarify the substantive significance of these patterns, beyond their statistical robustness. These results point to the institutional fragility of regimes where executive authority is highly centralised and unchecked. Additionally, the protective effects of democratic institutions and Cold War-era international structures warrant greater attention in discussion of executive stability and regime resilience. The implications of these findings for policy and democratic governance will be explored in detail in the final chapter.

= Summary
<summary>
This chapter provides a quantitative analysis of the determinants of autocoup attempts, addressing a notable gap in the existing literature, which has often been hindered by conceptual imprecision and the absence of systematic empirical data. It advances the central argument that the likelihood of autocoup attempts is shaped significantly by the structural configuration of political power within regimes, operationalised through regime type. Employing both standard logistic regression and Firth's bias-reduced logit model, the analysis demonstrates that personalist autocracies and presidential democracies are markedly more susceptible to autocoup attempts than dominant-party regimes. Specifically, the odds of an autocoup are estimated to be approximately three times higher in personalist autocracies and nearly five times higher in presidential democracies relative to the baseline category.

These findings lend empirical support to the hypothesis that such regime types possess structural vulnerabilities that facilitate extra-constitutional power consolidation by incumbents. In addition to regime type, the analysis identifies several other statistically significant covariates: population size, the degree of democratic institutionalisation, and the broader historical context of the Cold War all exert discernible effects on the probability of autocoup occurrence. By examining the strategic incentives confronting incumbent leaders across diverse institutional contexts, the study contributes to a more nuanced understanding of irregular leadership transitions.

Nevertheless, the analysis also underscores several conceptual and methodological challenges that warrant further investigation. Unlike traditional coups---which may occur at various stages of a regime's lifespan and are often subject to recurrence---autocoups appear to follow distinct temporal patterns. For instance, their likelihood may be comparatively low during the initial stages of a leader's tenure, increasing as the conclusion of a constitutional term approaches. Moreover, while a successful extension of tenure may reduce the short-term risk of subsequent attempts, empirical cases such as those of Presidents Putin and Lukashenko suggest that incumbents may engage in serial autocoup behaviour.

To render the analysis tractable, this study adopts the simplifying assumption that an autocoup attempt occurs only once per leadership tenure. While analytically expedient, this assumption highlights the need for future research to explore the temporal dynamics and sequencing of autocoup activity. Such inquiries would usefully complement the present findings by offering deeper insights into the long-term patterns of institutional adaptation, authoritarian durability, and democratic erosion.

#bibliography("references.bib")

