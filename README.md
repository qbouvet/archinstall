Everything that I like to keep nearby when installing arch linux, version-controlled.


#### 1/ Checklists

steps.yml  
  * List of the usual install steps.  
  * YAML formatting is only for clarity / structure.  
  * I don't plan on automating anything in a near future.  
  
pkgs.sh  
  * List usual packages in different groups (core packages, DE, apps)   
  * Outputs lists for pacman / yay. Ex:   
  *  * pacman -S $(./pkg.sh system)  
  *  * yay -S $(./pkg.sh plasma) $(./pkg.sh apps)  


#### 2/ Dotfiles

Managed with dotdrop.



#### 3/ Homemade install scripts

For various devices, in particular raspbery pi3 / pi0.  
Not really used anymore. 
