Everything that I like to keep nearby while installing arch linux, version-controlled.



#### 1/ Checklists

steps.yml  
  * List of the usual install steps.  
  * YAML formatting is only for clarity / structure.  
  * Nothing is automated, nor will be in a near future
  
pkgs.sh  
  * Reference packages & output lists for use with pacman / yay.
  * Ex:   
  *  * `pacman -S $(./pkg.sh amd nvidia pacstrap)`  
  *  * `yay -S $(./pkg.sh system apps plasma)`



#### 2/ Dotfiles

Managed with dotdrop.



#### 3/ Homemade install scripts

For various devices, in particular raspbery pi3 / pi0.  

Kept for reference, but it's old stuff.
