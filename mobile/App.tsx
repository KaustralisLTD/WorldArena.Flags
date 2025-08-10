import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'react-native';

// Screens
import HomeScreen from './src/screens/HomeScreen';
import GameScreen from './src/screens/GameScreen';
import StatisticsScreen from './src/screens/StatisticsScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import GameResultScreen from './src/screens/GameResultScreen';

// Define navigation types
export type RootStackParamList = {
  Home: undefined;
  Game: undefined;
  GameResult: {
    score: number;
    totalQuestions: number;
    correctAnswers: number;
    accuracy: number;
    duration: number;
  };
  Statistics: undefined;
  Settings: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();

const App: React.FC = () => {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" backgroundColor="#fff" />
      <NavigationContainer>
        <Stack.Navigator
          initialRouteName="Home"
          screenOptions={{
            headerStyle: {
              backgroundColor: '#4A90E2',
            },
            headerTintColor: '#fff',
            headerTitleStyle: {
              fontWeight: 'bold',
            },
          }}
        >
          <Stack.Screen 
            name="Home" 
            component={HomeScreen} 
            options={{ 
              title: 'Флаги Мира',
              headerShown: false,
            }} 
          />
          <Stack.Screen 
            name="Game" 
            component={GameScreen} 
            options={{ 
              title: 'Игра',
              headerShown: false,
              gestureEnabled: false,
            }} 
          />
          <Stack.Screen 
            name="GameResult" 
            component={GameResultScreen} 
            options={{ 
              title: 'Результаты',
              headerShown: false,
              gestureEnabled: false,
            }} 
          />
          <Stack.Screen 
            name="Statistics" 
            component={StatisticsScreen} 
            options={{ 
              title: 'Статистика',
            }} 
          />
          <Stack.Screen 
            name="Settings" 
            component={SettingsScreen} 
            options={{ 
              title: 'Настройки',
            }} 
          />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
};

export default App; 