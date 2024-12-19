#!/bin/bash
set -e
read -p "Do you need Swap space for your work?(Yes/No): " swap

if [[ $swap =~ [Yy]es ]]; then 
        read -p "Enter the name of swap space/file you want to create: " swap_filename
        read -p "Enter the size of the swapfile (make sure to add unit to the value such as G,M,B): " size_of_swapfile

        ### Switch to root directory ###
        cd /
        ### Create the swap file ###
        if [[ -e $swap_filename ]]; then 
                echo "File already exists"
        else
                sudo touch $swap_filename
        fi 

        ### Provide the right permissions and ownership to the file     ###
        sudo chmod 600 -R $swap_filename
        sudo chown -R root:root $swap_filename  

        ### Checking the total memory of swap ###
        swap_mem="$(free -t|awk 'NR==3 {print $2}')"
        echo "Your current swap size is $swap_mem"
        if [[ $swap_mem == 0 ]]; then 
                ### Allocating desired swap space to swap file ###
                sudo fallocate -l $size_of_swapfile $swap_filename

                ### Marking file as swap ###
                sudo mkswap $swap_filename > /dev/null

                ### Enabling the swap file ###
                sudo swapon $swap_filename

                ### Making Swap file permanent ###
                echo "$swap_filename none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null
                echo "Swap space enabling steps are complete"

                ### Adjusting the Swappiness Property ###
                swappiness="$(cat /proc/sys/vm/swappiness)" 
                        if [[ $swappiness -ge 40 && $swappiness -le 60 ]]; then 
                                echo "Checking the swappiness parameter...."
                                echo "Swappiness Paramater in range"
                                echo "No change to swappiness parameter"
                                else 
                                swappiness=60
                                echo $swappiness | sudo tee -a /proc/sys/vm/swappiness
                                ### Making swappiness parameter permanent ###
                                echo "vm.swappiness=$swappiness" | sudo tee -a /etc/sysctl.conf
                        fi

                ### Verify that the swap is available ###
                if [[ $(free -t|awk 'NR==3 {print $2}') -ne 0 ]]; then 
                        echo "********************************"
                        echo "Swap is enabled and ready to use"
                        echo "********************************"
			echo "Your latest swap size is $(free -t|awk 'NR==3 {print $2}')B"
                else
                        echo "************************************************************************"
                        echo "Swapping procedure failed. Re-run the script or check the logs for error"
                        echo "************************************************************************"
                fi
        else 
        echo "*******************************************************************"
        echo "Swap space is enabled. Use the free command to check the swap space"
        echo "*******************************************************************"
        fi
else
echo "***********************************************"
echo "Skipping the procedure to enable the swap space"
echo "***********************************************"
fi
