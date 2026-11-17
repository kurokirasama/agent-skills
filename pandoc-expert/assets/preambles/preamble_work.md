---
number_sections: true
output: pdf_document
graphics: true
colorlinks: true
linkcolor: blue
fontsize: 12pt
header-includes:
  - '\usepackage{graphics}'
  - '\usepackage{amsmath}'
  - '\usepackage[spanish,activeacute,es-tabla]{babel}'
  - '\usepackage{hyphenat}'
  - '\usepackage{dsfont}'
  - '\usepackage[algoruled]{algorithm2e}'
  - '\usepackage{ragged2e}'
  - '\usepackage{hyperref}'
  - '\usepackage[all]{hypcap}'
  - '\newcommand{\algorithmiccomment}[1]{\hfill\# #1 }'
  - '\newcommand{\m}{\displaystyle}'
  - '\hyphenation{va-lo-res des-cri-tas mul-ti-di-men-sio-na-les ca-rac-te-ri-za-do}'
  - '\spanishdecimal{.}'
  - '\newcommand{\refer}[3][]{\hyperref[#3]{#2~\ref*{#3}#1}}'
  - '\usepackage[left=2cm,right=2cm,top=3cm,bottom=3cm]{geometry}'
  - '\usepackage{csvsimple}'
  - '\usepackage{tikz}'
  - '\usetikzlibrary{decorations.pathreplacing,automata,arrows,shadows,patterns,shapes}'
  - '\usepackage{caption}'
  - '\usepackage{fontspec}'
  - '\usepackage{csquotes}'
  - '\usepackage{fvextra}'
  - '\fvset{breaklines=true,breakanywhere=true}'
  - '\DefineVerbatimEnvironment{verbatim}{Verbatim}{breaklines=true,breakanywhere=true,fontsize=\small}'
  - '\DefineVerbatimEnvironment{Highlighting}{Verbatim}{breaklines=true,breakanywhere=true,commandchars=\\\{\},fontsize=\small}'
  - '\setcounter{tocdepth}{5}'
  - '\setcounter{secnumdepth}{5}'
  - '\makeatletter'
  - '\renewcommand\subparagraph{\@startsection{subparagraph}{5}{\z@}{3.25ex \@plus1ex \@minus.2ex}{1.5ex \@plus.2ex}{\normalfont\normalsize\bfseries}}'
  - '\makeatother'
  - '\usepackage{float}'
  - '\usepackage{array}'
  - '\renewcommand{\labelitemi}{\textbullet}'
  - '\newcommand\Monthname[1][EMPTY]{\ifnum1=#1Enero\else \ifnum2=#1Febrero\else \ifnum3=#1Marzo\else \ifnum4=#1Abril\else \ifnum5=#1Mayo\else \ifnum6=#1Junio\else \ifnum7=#1Julio\else \ifnum8=#1Agosto\else \ifnum9=#1Septiembre\else \ifnum10=#1Octubre\else \ifnum11=#1Noviembre\else \ifnum12=#1Diciembre\else \fi\fi\fi\fi\fi\fi\fi\fi\fi\fi\fi\fi }'
---

\begin{minipage}{\textwidth}
\begin{minipage}[t]{0.08\textwidth}
\vspace{0pt}
\includegraphics[width=\linewidth]{work.jpg}
\end{minipage}\hfill
\begin{minipage}[t]{9cm}
\vspace{0pt}
\centering
\small {\bf \rm
		{{\footnotesize UNIVERSIDAD DEL B\'IO-B\'IO} \\
		{\scriptsize FACULTAD DE CIENCIAS}  \\
		{\scriptsize DEPARTAMENTO DE ESTAD\'ISTICA}  \\
		{\scriptsize Profesor: Author Name}\\
		{\scriptsize \Monthname[\month{}]\ \the\year{} }}}
\end{minipage}\hfill
\begin{minipage}[t]{0.2\textwidth}
\vspace{0pt}
\includegraphics[width=\linewidth]{dest.jpg}
\end{minipage}
\end{minipage}
\vskip0.4cm
\hrule
\begin{center}
	{\bf {Ciencia de Datos en la Terminal Linux}}
	\vskip0.2cm
\end{center}
\hrule
\vskip0.4cm
