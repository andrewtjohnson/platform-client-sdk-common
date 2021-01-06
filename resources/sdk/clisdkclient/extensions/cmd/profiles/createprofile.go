package profiles

import (
	"fmt"
	"gc/config"
	"gc/mocks"
	"gc/restclient"
	"log"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func constructConfig(profileName string, environment string, clientID string, clientSecret string) config.Configuration {
	config := &mocks.MockClientConfig{}

	config.ProfileNameFunc = func() string {
		return profileName
	}

	config.EnvironmentFunc = func() string {
		return environment
	}

	config.ClientIDFunc = func() string {
		return clientID
	}

	config.ClientSecretFunc = func() string {
		return clientSecret
	}
	return config
}

func requestUserInput() config.Configuration {
	var name string
	var environment string
	var clientID string
	var clientSecret string

	fmt.Print("Profile Name [DEFAULT]: ")
	fmt.Scanln(&name)

	if name == "" {
		name = "DEFAULT"
	}

	fmt.Printf("Environment [mypurecloud.com]: ")
	fmt.Scanln(&environment)

	if environment == "" {
		environment = "mypurecloud.com"
	}

	for true {
		fmt.Printf("Client ID: ")
		fmt.Scanln(&clientID)
		if len(strings.TrimSpace(clientID)) != 0 {
			break
		}
	}

	for true {
		fmt.Printf("Client Secret: ")
		fmt.Scanln(&clientSecret)
		if len(strings.TrimSpace(clientSecret)) != 0 {
			break
		}
	}

	return constructConfig(name, environment, clientID, clientSecret)
}

func overrideConfig(name string) bool {
	//The file does not exist and therefore can not be overridden
	if err := viper.ReadInConfig(); err != nil {
		return true
	}

	config, err := config.GetConfig(name)

	//profile already exists we will get a nil back and we must resolve the results
	if err == nil && config.ProfileName() != "" {
		for true {
			var overwrite string
			fmt.Printf("Profile name %s already exists in the config file. Overwrite (Y/N): ", name)
			fmt.Scanln(&overwrite)

			if strings.ToUpper(overwrite) == "N" {
				return false
			}

			if strings.ToUpper(overwrite) == "Y" {
				break
			}
		}
	}

	return true
}

func validateCredentials(config config.Configuration) bool {
	oauthToken, err := restclient.Login(config)
	if err != nil || oauthToken.AccessToken == "" {
		//Check to see if its an HTTP error and if its check to see if its what we are expecting
		if _, ok := err.(*restclient.HttpStatusError); ok {
			return false
		}
		log.Fatal(err)
	}

	return true
}

var createProfilesCmd = &cobra.Command{
	Use:   "new",
	Short: "Creates a new profile",
	Long:  `Creates a new profile`,

	Run: func(cmd *cobra.Command, args []string) {

		newConfig := requestUserInput()

		if overrideConfig(newConfig.ProfileName()) == false {
			fmt.Println("Exiting profile creation process")
			os.Exit(1)
		}

		if validateCredentials(newConfig) == false {
			fmt.Println("The credentials provided are not valid.")
			os.Exit(1)
		}

		if err := config.SaveConfig(newConfig); err != nil {
			fmt.Print(err)
			os.Exit(1)
		}

		fmt.Printf("Profile %s saved.\n", newConfig.ProfileName())
	},
}