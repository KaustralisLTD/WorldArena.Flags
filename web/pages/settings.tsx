import { useState } from 'react';
import { useGameStore } from '../src/lib/gameStore';
import { useTranslation } from '../src/lib/translations';
import Layout from '../src/components/Layout';

export default function Settings() {
  const { language, theme, setLanguage, setTheme, clearData } = useGameStore();
  const { t } = useTranslation(language);
  const [showClearConfirm, setShowClearConfirm] = useState(false);

  const languages = [
    { code: 'en', name: 'English', flag: '🇺🇸' },
    { code: 'es', name: 'Español', flag: '🇪🇸' },
    { code: 'uk', name: 'Українська', flag: '🇺🇦' },
    { code: 'ca', name: 'Català', flag: '🏴󠁥󠁳󠁣󠁴󠁿' },
    { code: 'ru', name: 'Русский', flag: '🇷🇺' },
    { code: 'zh', name: '中文', flag: '🇨🇳' },
  ];

  const themes = [
    { value: 'light', label: t.light, icon: '☀️' },
    { value: 'dark', label: t.dark, icon: '🌙' },
    { value: 'system', label: t.system, icon: '💻' },
  ];

  const handleClearData = () => {
    clearData();
    setShowClearConfirm(false);
  };

  return (
    <Layout title={t.settings} showBackButton>
      <div className="container mx-auto px-4 py-8 max-w-2xl">
        <div className="space-y-6">
          {/* Language Settings */}
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
              {t.language}
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {languages.map((lang) => (
                <button
                  key={lang.code}
                  onClick={() => setLanguage(lang.code)}
                  className={`flex items-center space-x-3 p-3 rounded-lg border transition-colors ${
                    language === lang.code
                      ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400'
                      : 'border-gray-200 dark:border-gray-700 hover:border-primary-300 dark:hover:border-primary-600'
                  }`}
                >
                  <span className="text-xl">{lang.flag}</span>
                  <span className="font-medium">{lang.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Theme Settings */}
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
              {t.theme}
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {themes.map((themeOption) => (
                <button
                  key={themeOption.value}
                  onClick={() => setTheme(themeOption.value as 'light' | 'dark' | 'system')}
                  className={`flex items-center space-x-3 p-3 rounded-lg border transition-colors ${
                    theme === themeOption.value
                      ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400'
                      : 'border-gray-200 dark:border-gray-700 hover:border-primary-300 dark:hover:border-primary-600'
                  }`}
                >
                  <span className="text-xl">{themeOption.icon}</span>
                  <span className="font-medium">{themeOption.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Data Management */}
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
              {t.dataManagement}
            </h2>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
                <div>
                  <h3 className="font-semibold text-red-800 dark:text-red-200">
                    {t.clearData}
                  </h3>
                  <p className="text-sm text-red-600 dark:text-red-300">
                    {t.clearAllStats}
                  </p>
                </div>
                <button
                  onClick={() => setShowClearConfirm(true)}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  {t.clear}
                </button>
              </div>
            </div>
          </div>

          {/* App Info */}
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
              {t.aboutApp}
            </h2>
            <div className="space-y-3 text-sm text-gray-600 dark:text-gray-400">
              <div className="flex justify-between">
                <span>{t.version}:</span>
                <span className="font-medium">1.0.0</span>
              </div>
              <div className="flex justify-between">
                <span>{t.platform}:</span>
                <span className="font-medium">Web PWA</span>
              </div>
              <div className="flex justify-between">
                <span>{t.lastUpdate}:</span>
                <span className="font-medium">2025</span>
              </div>
            </div>
          </div>
        </div>

        {/* Clear Data Confirmation Modal */}
        {showClearConfirm && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
                {t.confirmAction}
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-6">
                {t.clearDataConfirm}
              </p>
              <div className="flex space-x-3">
                <button
                  onClick={() => setShowClearConfirm(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                  {t.cancel}
                </button>
                <button
                  onClick={handleClearData}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  {t.clear}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
} 