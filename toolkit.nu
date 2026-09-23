#!/usr/bin/env nu

def --wrapped main [...rest] {
  const pathToSelf = path self
  let nameOfSelf = $pathToSelf | path parse | get stem
  if $rest in [ [-h] [--help] ] {
    nu -c $'use ($pathToSelf); scope modules | where name == ($nameOfSelf) | get 0.commands.name'
  } else {
    nu -c $'use ($pathToSelf); ($nameOfSelf) ($rest | str join (" "))'
  }
}

# Given a url to a pull request against a repo in our fork network, then apply the diff and make a commit
export def import-pull-request [
  pull_request # Url to a pull request (eg <https://github.com/mkrl/misbrands/pull/86>)
] {
  let pull_request_data = $pull_request
  | parse "{rest}github.com/{user}/{repo}/pull/{pull_request_id}"
  | first
  | http get $"https://api.github.com/repos/($in.user)/($in.repo)/pulls/($in.pull_request_id)"
  let message = $pull_request_data.title
  let user = $pull_request_data.user.login
  let url = ($pull_request_data.head.repo.html_url? | default deleted)
  let commit_message = $"($message) \(credit @($user)) <($url)>"
  http get $pull_request_data.diff_url | git apply
  git add -A
  git commit -m $commit_message
}

export def update-readme [] {
$"![An assortment of various logos that look like other famous brands but actually have their competitors' name]\(https://repository-images.githubusercontent.com/765213285/cb859884-eeb2-462a-a50c-8976873d4cb4)

<details>
<summary>
Timeline
</summary>

- May 2019: [@samdbeckham]\(https://github.com/samdbeckham)'s legendary javascript-java sticker \([website]\(https://samdbeckham.gitlab.io/javascript_sticker/)) \([tweet]\(https://twitter.com/samdbeckham/status/1129722966118457344))
- Aug 2019: [@mkrl]\(https://github.com/mkrl)'s misbrand repo \([repo]\(https://github.com/mkrl/misbrands))
- May 2022: [@ohmyhub]\(https://github.com/ohmyhub)'s fork \([repo]\(https://github.com/ohmyhub/misbrands))
- Feb 2024: [@pReya]\(https://github.com/pReya)'s fork \([repo]\(https://github.com/pReya/cursed-programming-stickers))
- Mar 2024: This fork!

</details>

<details>
<summary>
FAQ
</summary>

### Can I print these?
Of course, that's why those are here.

### Can I buy these?
Yes, you can! Not from me, but from any custom sticker vendor of your choice.

### Will there be more?
This is a fork of the original repo that hadn't been updated in some time. I'm
working on adding new logos that were submitted as pull requests to the original
repo.

### How do I make a misbrand?
To make a misbrand, choose two existing brands. Generally the fanbase for the
brands have as much overlap \(eg: Rust & Golang) and/or contention \(eg: Vim & VSCode)
as possible or the brands have similar market niches \(eg: OpenVPN & NordVPN).

Once the two victum brands are chosen. Take the style \(eg: theme/design) of one
brand and join it with the text of the other brand. Viola!

Check the FAQ for more resources on DIY-ing a misbrand

### How do I find images/logos for brands?
- Look for the 'Press' or 'Media' section on the website, there will usually be assets that make a good starting place
- Search the codebase for `svg`

### How do I create an svg?

If you don't know where to start, use Inkscape \([website]\(https://inkscape.org))
\([gitlab]\(https://gitlab.com/inkscape/inkscape)). There are tutorials and resources
online, just search for 'How do I do XYZ in inkscape?'

### I have a misbrand. How do I contribute?
There are two ways to submit a misbrand:

- Issue: Create an issue on this repo with the image!
- Pull Request: Click the fork button, add the image to your copy of this repo, go to 'Pull Requests' and click 'New pull requests'
    - Please follow the file and commit conventions below

</details>

<details>
<summary>
Naming Convention
</summary>

There are two naming conventions:
- One for files to make them easier to find and understand
- One for submitting images you didn't create

### Files

For all the images, our convention is
- `{text}-{style}.svg`

Example: The text says python in the logo style of php. `python-php.svg`

If there is a file with that name already existing simply add a dash and a
number starting with 02 and incrementing up from there.

Example: You submit a misbrand that says emacs in the style of the vim,
there is already an `emacs-vim.svg` in the repo. Name your file `emacs-vim-02.svg`.

### Commits

- If you created the image, do whatever you want for the commit message!
- If you are adding an image you didn't create, structure the message like so:
    - `{text} in the style of {style} \(credit @{user}) <{url}>`
    - Where `{user}` is the user who created the image
    - And `{url}` is the repo/website the image came from

</details>

<details>
<summary>
Misbrands by Text
</summary>

(misbrands-by-text-as-md)
</details>

<details>
<summary>
Misbrands by Style
</summary>

(misbrands-by-style-as-md)
</details>
"
  | save -f README.md
}

export def misbrands-by-text-as-md [] {
  misbrands
  | group-by --to-table text
  | each {|it|
    [
      '<details>'
      '<summary>'
      $it.text
      '</summary>'
      ''
      ...($it.items | each { misbrand-by-text-as-md })
      '</details>'
    ]
  }
  | flatten
  | str join (char newline)
}

export def misbrand-by-text-as-md [] {
  $"### ($in.style)(char newline)![($in.style)]\(($in.path))(char newline)"
}

export def misbrands-by-style-as-md [] {
  misbrands
  | sort-by style text
  | group-by --to-table style
  | each {|it|
    [
      '<details>'
      '<summary>'
      $it.style
      '</summary>'
      ''
      ...($it.items | each { misbrand-by-style-as-md })
      '</details>'
    ]
  }
  | flatten
  | str join (char newline)
}

export def misbrand-by-style-as-md [] {
  $"### ($in.text)(char newline)![($in.text)]\(($in.path))(char newline)"
}

export def misbrands [] {
  ls *
  | where name =~ '(png|svg)$'
  | each {|it|
    $it.name
    | parse -r '^(?<text>[^-]+)-(?<style>[^-]+)-?(?<index>\d+)?\.(?<type>.+)$'
    | get --optional 0
    | default {}
    | upsert index { if ($in | is-empty) { 1 } else { into int } }
    | insert path $it.name
  }
}
