import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../../App';

type SettingsScreenNavigationProp = StackNavigationProp<RootStackParamList, 'Settings'>;

interface Props {
  navigation: SettingsScreenNavigationProp;
}

const SettingsScreen: React.FC<Props> = ({ navigation }) => {
  const [selectedLanguage, setSelectedLanguage] = useState('ru');
  const [selectedTheme, setSelectedTheme] = useState('system');
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [vibrationEnabled, setVibrationEnabled] = useState(true);
  const [notificationsEnabled, setNotificationsEnabled] = useState(false);

  const languages = [
    { code: 'en', name: 'English', flag: '🇺🇸' },
    { code: 'ru', name: 'Русский', flag: '🇷🇺' },
    { code: 'es', name: 'Español', flag: '🇪🇸' },
    { code: 'uk', name: 'Українська', flag: '🇺🇦' },
    { code: 'ca', name: 'Català', flag: '🏴' },
    { code: 'zh', name: '中文', flag: '🇨🇳' },
  ];

  const themes = [
    { key: 'light', name: 'Светлая', icon: '☀️' },
    { key: 'dark', name: 'Темная', icon: '🌙' },
    { key: 'system', name: 'Системная', icon: '🔄' },
  ];

  const handleLanguageChange = (languageCode: string) => {
    setSelectedLanguage(languageCode);
    // TODO: Implement language change logic
    Alert.alert('Язык изменен', `Выбран язык: ${languages.find(l => l.code === languageCode)?.name}`);
  };

  const handleThemeChange = (themeKey: string) => {
    setSelectedTheme(themeKey);
    // TODO: Implement theme change logic
    Alert.alert('Тема изменена', `Выбрана тема: ${themes.find(t => t.key === themeKey)?.name}`);
  };

  const resetStatistics = () => {
    Alert.alert(
      'Сбросить статистику?',
      'Вся ваша статистика и прогресс будут удалены. Это действие нельзя отменить.',
      [
        { text: 'Отмена', style: 'cancel' },
        {
          text: 'Сбросить',
          style: 'destructive',
          onPress: () => {
            // TODO: Implement reset statistics
            Alert.alert('Статистика сброшена', 'Вся статистика была удалена');
          },
        },
      ]
    );
  };

  const exportData = () => {
    Alert.alert('Экспорт данных', 'Функция экспорта данных будет доступна в следующей версии');
  };

  const contactSupport = () => {
    Alert.alert(
      'Связаться с поддержкой',
      'Выберите способ связи:',
      [
        { text: 'Отмена', style: 'cancel' },
        { text: 'Email', onPress: () => Alert.alert('Email', 'support@flagsworld.com') },
        { text: 'Telegram', onPress: () => Alert.alert('Telegram', '@flagsworld_support') },
      ]
    );
  };

  const rateApp = () => {
    Alert.alert('Оценить приложение', 'Спасибо за желание оценить наше приложение!');
  };

  const shareApp = () => {
    Alert.alert('Поделиться приложением', 'Расскажите друзьям о Флаги Мира!');
  };

  return (
    <ScrollView style={styles.container}>
      {/* Language Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🌐 Язык интерфейса</Text>
        {languages.map((language) => (
          <TouchableOpacity
            key={language.code}
            style={styles.option}
            onPress={() => handleLanguageChange(language.code)}
          >
            <View style={styles.optionLeft}>
              <Text style={styles.optionIcon}>{language.flag}</Text>
              <Text style={styles.optionText}>{language.name}</Text>
            </View>
            <View style={styles.radioButton}>
              {selectedLanguage === language.code && (
                <View style={styles.radioButtonSelected} />
              )}
            </View>
          </TouchableOpacity>
        ))}
      </View>

      {/* Theme Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🎨 Тема оформления</Text>
        {themes.map((theme) => (
          <TouchableOpacity
            key={theme.key}
            style={styles.option}
            onPress={() => handleThemeChange(theme.key)}
          >
            <View style={styles.optionLeft}>
              <Text style={styles.optionIcon}>{theme.icon}</Text>
              <Text style={styles.optionText}>{theme.name}</Text>
            </View>
            <View style={styles.radioButton}>
              {selectedTheme === theme.key && (
                <View style={styles.radioButtonSelected} />
              )}
            </View>
          </TouchableOpacity>
        ))}
      </View>

      {/* Gameplay Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🎮 Игровые настройки</Text>
        
        <View style={styles.switchOption}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>🔊</Text>
            <View>
              <Text style={styles.optionText}>Звуковые эффекты</Text>
              <Text style={styles.optionDescription}>Включить звуки в игре</Text>
            </View>
          </View>
          <Switch
            value={soundEnabled}
            onValueChange={setSoundEnabled}
            trackColor={{ false: '#E5E5E5', true: '#4A90E2' }}
            thumbColor={soundEnabled ? '#fff' : '#f4f3f4'}
          />
        </View>

        <View style={styles.switchOption}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>📳</Text>
            <View>
              <Text style={styles.optionText}>Вибрация</Text>
              <Text style={styles.optionDescription}>Вибрация при ответах</Text>
            </View>
          </View>
          <Switch
            value={vibrationEnabled}
            onValueChange={setVibrationEnabled}
            trackColor={{ false: '#E5E5E5', true: '#4A90E2' }}
            thumbColor={vibrationEnabled ? '#fff' : '#f4f3f4'}
          />
        </View>

        <View style={styles.switchOption}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>🔔</Text>
            <View>
              <Text style={styles.optionText}>Уведомления</Text>
              <Text style={styles.optionDescription}>Напоминания о тренировках</Text>
            </View>
          </View>
          <Switch
            value={notificationsEnabled}
            onValueChange={setNotificationsEnabled}
            trackColor={{ false: '#E5E5E5', true: '#4A90E2' }}
            thumbColor={notificationsEnabled ? '#fff' : '#f4f3f4'}
          />
        </View>
      </View>

      {/* Data & Privacy */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🔒 Данные и конфиденциальность</Text>
        
        <TouchableOpacity style={styles.actionOption} onPress={exportData}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>📤</Text>
            <View>
              <Text style={styles.optionText}>Экспорт данных</Text>
              <Text style={styles.optionDescription}>Сохранить статистику</Text>
            </View>
          </View>
          <Text style={styles.optionArrow}>›</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionOption} onPress={resetStatistics}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>🗑️</Text>
            <View>
              <Text style={[styles.optionText, styles.dangerText]}>Сбросить статистику</Text>
              <Text style={styles.optionDescription}>Удалить все данные</Text>
            </View>
          </View>
          <Text style={styles.optionArrow}>›</Text>
        </TouchableOpacity>
      </View>

      {/* Support & Feedback */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>💬 Поддержка и отзывы</Text>
        
        <TouchableOpacity style={styles.actionOption} onPress={rateApp}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>⭐</Text>
            <View>
              <Text style={styles.optionText}>Оценить приложение</Text>
              <Text style={styles.optionDescription}>Помочь нам стать лучше</Text>
            </View>
          </View>
          <Text style={styles.optionArrow}>›</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionOption} onPress={shareApp}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>📱</Text>
            <View>
              <Text style={styles.optionText}>Поделиться приложением</Text>
              <Text style={styles.optionDescription}>Рассказать друзьям</Text>
            </View>
          </View>
          <Text style={styles.optionArrow}>›</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionOption} onPress={contactSupport}>
          <View style={styles.optionLeft}>
            <Text style={styles.optionIcon}>🆘</Text>
            <View>
              <Text style={styles.optionText}>Связаться с поддержкой</Text>
              <Text style={styles.optionDescription}>Сообщить о проблеме</Text>
            </View>
          </View>
          <Text style={styles.optionArrow}>›</Text>
        </TouchableOpacity>
      </View>

      {/* App Info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>ℹ️ О приложении</Text>
        
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Версия приложения:</Text>
          <Text style={styles.infoValue}>1.0.0</Text>
        </View>

        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Версия базы данных:</Text>
          <Text style={styles.infoValue}>2024.1</Text>
        </View>

        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Последнее обновление:</Text>
          <Text style={styles.infoValue}>15 января 2024</Text>
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          🌎 Флаги Мира
        </Text>
        <Text style={styles.footerSubtext}>
          Изучайте географию с удовольствием!
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  section: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    paddingVertical: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  option: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  optionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  optionIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  optionText: {
    fontSize: 16,
    color: '#2C3E50',
  },
  optionDescription: {
    fontSize: 14,
    color: '#7F8C8D',
    marginTop: 2,
  },
  dangerText: {
    color: '#E74C3C',
  },
  optionArrow: {
    fontSize: 20,
    color: '#7F8C8D',
  },
  radioButton: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#4A90E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  radioButtonSelected: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#4A90E2',
  },
  switchOption: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  actionOption: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  infoLabel: {
    fontSize: 14,
    color: '#7F8C8D',
  },
  infoValue: {
    fontSize: 14,
    color: '#2C3E50',
    fontWeight: '600',
  },
  footer: {
    alignItems: 'center',
    paddingVertical: 30,
    paddingHorizontal: 20,
  },
  footerText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#4A90E2',
    marginBottom: 4,
  },
  footerSubtext: {
    fontSize: 14,
    color: '#7F8C8D',
    textAlign: 'center',
  },
});

export default SettingsScreen; 