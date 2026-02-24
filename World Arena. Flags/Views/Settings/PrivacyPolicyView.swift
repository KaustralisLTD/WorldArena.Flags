import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfile: UserProfile
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(getPrivacyContent())
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundColor(.primary)
                }
                .padding(20)
            }
            .background(systemGroupedBackground)
            .navigationTitle(getTitle())
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #endif
            }
        }
    }
    
    private func getTitle() -> String {
        let languageCode = Locale.current.languageCode ?? "en"
        
        switch languageCode {
        case "ru": return "Политика конфиденциальности"
        case "es": return "Política de Privacidad"
        case "uk": return "Політика конфіденційності"
        case "ca": return "Política de Privacitat"
        case "zh": return "隐私政策"
        default: return "Privacy Policy"
        }
    }
    
    private func getPrivacyContent() -> String {
        let languageCode = Locale.current.languageCode ?? "en"
        
        switch languageCode {
        case "ru":
            return russianPrivacy
        case "es":
            return spanishPrivacy
        case "uk":
            return ukrainianPrivacy
        case "ca":
            return catalanPrivacy
        case "zh":
            return chinesePrivacy
        default:
            return englishPrivacy
        }
    }
    
    private var englishPrivacy: String {
        """
        PRIVACY POLICY
        
        Last updated: \(getCurrentDate())
        
        World Arena Games ("we," "our," or "us") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and protect your information when you use the World Arena Flags mobile application ("App").
        
        1. INFORMATION WE COLLECT
        
        1.1 Information You Provide
        • Account information (if you choose to create an account)
        • Game preferences and settings
        • Feedback and communications you send to us
        
        1.2 Information Automatically Collected
        • Game statistics and progress data
        • Device information (device type, operating system version)
        • Usage analytics (game sessions, features used)
        • Crash reports and error logs
        
        1.3 Information We Do Not Collect
        • We do not collect your real name, email address, or phone number unless you voluntarily provide it
        • We do not access your contacts, photos, or other personal files
        • We do not track your location
        
        2. HOW WE USE YOUR INFORMATION
        
        2.1 To Provide and Improve Our Service
        • Deliver game functionality and features
        • Save your game progress and preferences
        • Analyze usage patterns to improve the App
        • Fix bugs and technical issues
        
        2.2 To Communicate With You
        • Respond to your inquiries and support requests
        • Send important updates about the App
        • Provide customer support
        
        2.3 For Analytics and Research
        • Understand how users interact with the App
        • Improve game design and user experience
        • Develop new features and content
        
        3. HOW WE STORE AND PROTECT YOUR INFORMATION
        
        3.1 Data Storage
        • Most of your data is stored locally on your device
        • Some data may be stored on secure cloud servers for backup purposes
        • We use industry-standard encryption to protect your data
        
        3.2 Data Security
        • We implement appropriate technical and organizational measures
        • Regular security assessments and updates
        • Limited access to personal information by authorized personnel only
        
        3.3 Data Retention
        • We retain your information only as long as necessary
        • You can delete your data at any time through the App settings
        • Inactive accounts may be automatically deleted after extended periods
        
        4. SHARING YOUR INFORMATION
        
        4.1 We Do Not Sell Your Information
        • We never sell, rent, or trade your personal information
        • Your privacy is not a commodity to us
        
        4.2 Limited Sharing
        We may share your information only in these circumstances:
        • With your explicit consent
        • To comply with legal obligations
        • To protect our rights and the safety of our users
        • In connection with a business transfer (merger, acquisition)
        
        4.3 Third-Party Services
        • We may use third-party analytics services (anonymized data only)
        • Cloud storage providers for data backup (encrypted)
        • These services are bound by strict privacy agreements
        
        5. YOUR PRIVACY RIGHTS
        
        5.1 Access and Control
        • View your stored data through the App settings
        • Update or correct your information
        • Delete your account and associated data
        
        5.2 Data Portability
        • Export your game data and statistics
        • Transfer your data to another device
        
        5.3 Opt-Out Rights
        • Disable analytics data collection
        • Turn off crash reporting
        • Manage notification preferences
        
        6. CHILDREN'S PRIVACY
        
        6.1 Age Restrictions
        • Our App is suitable for users of all ages
        • We do not knowingly collect personal information from children under 13
        • Parents can contact us to request deletion of their child's data
        
        6.2 Parental Controls
        • Parents can monitor and control their child's use of the App
        • No in-app purchases or social features that could expose children
        
        7. INTERNATIONAL DATA TRANSFERS
        
        7.1 Global Service
        • Our App is available worldwide
        • Data may be transferred to countries with different privacy laws
        • We ensure appropriate safeguards are in place
        
        8. COOKIES AND TRACKING
        
        8.1 Limited Use
        • We do not use cookies for web tracking
        • Local storage is used only for game functionality
        • No third-party advertising or tracking pixels
        
        9. CHANGES TO THIS PRIVACY POLICY
        
        9.1 Updates
        • We may update this policy from time to time
        • Material changes will be communicated through the App
        • Continued use constitutes acceptance of changes
        
        10. CONTACT US
        
        If you have questions about this Privacy Policy or our privacy practices:
        
        Email: privacy@worldarena.games
        Subject: Privacy Policy Inquiry
        
        We will respond to your inquiry within 30 days.
        
        11. EFFECTIVE DATE
        
        This Privacy Policy is effective as of the date listed at the top of this document.
        
        By using World Arena Flags, you acknowledge that you have read and understood this Privacy Policy and agree to our collection, use, and protection of your information as described herein.
        """
    }
    
    private var russianPrivacy: String {
        """
        ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ
        
        Последнее обновление: \(getCurrentDate())
        
        World Arena Games ("мы", "наш" или "нас") уважает вашу конфиденциальность и стремится защитить вашу личную информацию. Данная Политика конфиденциальности объясняет, как мы собираем, используем и защищаем вашу информацию при использовании мобильного приложения World Arena Flags ("Приложение").
        
        1. ИНФОРМАЦИЯ, КОТОРУЮ МЫ СОБИРАЕМ
        
        1.1 Информация, которую вы предоставляете
        • Информация об аккаунте (если вы решите создать аккаунт)
        • Игровые предпочтения и настройки
        • Отзывы и сообщения, которые вы нам отправляете
        
        1.2 Автоматически собираемая информация
        • Игровая статистика и данные о прогрессе
        • Информация об устройстве (тип устройства, версия операционной системы)
        • Аналитика использования (игровые сессии, используемые функции)
        • Отчеты о сбоях и журналы ошибок
        
        1.3 Информация, которую мы НЕ собираем
        • Мы не собираем ваше настоящее имя, адрес электронной почты или номер телефона, если вы добровольно не предоставите их
        • Мы не получаем доступ к вашим контактам, фотографиям или другим личным файлам
        • Мы не отслеживаем ваше местоположение
        
        2. КАК МЫ ИСПОЛЬЗУЕМ ВАШУ ИНФОРМАЦИЮ
        
        2.1 Для предоставления и улучшения нашего сервиса
        • Обеспечение игровой функциональности и возможностей
        • Сохранение вашего игрового прогресса и предпочтений
        • Анализ паттернов использования для улучшения Приложения
        • Исправление ошибок и технических проблем
        
        2.2 Для общения с вами
        • Ответы на ваши запросы и обращения в службу поддержки
        • Отправка важных обновлений о Приложении
        • Предоставление клиентской поддержки
        
        2.3 Для аналитики и исследований
        • Понимание того, как пользователи взаимодействуют с Приложением
        • Улучшение дизайна игры и пользовательского опыта
        • Разработка новых функций и контента
        
        3. КАК МЫ ХРАНИМ И ЗАЩИЩАЕМ ВАШУ ИНФОРМАЦИЮ
        
        3.1 Хранение данных
        • Большая часть ваших данных хранится локально на вашем устройстве
        • Некоторые данные могут храниться на защищенных облачных серверах для резервного копирования
        • Мы используем стандартное шифрование для защиты ваших данных
        
        3.2 Безопасность данных
        • Мы применяем соответствующие технические и организационные меры
        • Регулярные оценки безопасности и обновления
        • Ограниченный доступ к личной информации только авторизованному персоналу
        
        3.3 Хранение данных
        • Мы храним вашу информацию только столько, сколько необходимо
        • Вы можете удалить свои данные в любое время через настройки Приложения
        • Неактивные аккаунты могут быть автоматически удалены после длительных периодов
        
        4. ПЕРЕДАЧА ВАШЕЙ ИНФОРМАЦИИ
        
        4.1 Мы не продаем вашу информацию
        • Мы никогда не продаем, не сдаем в аренду и не торгуем вашей личной информацией
        • Ваша конфиденциальность для нас не товар
        
        4.2 Ограниченная передача
        Мы можем передавать вашу информацию только в следующих обстоятельствах:
        • С вашего явного согласия
        • Для соблюдения правовых обязательств
        • Для защиты наших прав и безопасности наших пользователей
        • В связи с передачей бизнеса (слияние, поглощение)
        
        4.3 Сторонние сервисы
        • Мы можем использовать сторонние аналитические сервисы (только анонимизированные данные)
        • Провайдеры облачного хранения для резервного копирования данных (зашифрованные)
        • Эти сервисы связаны строгими соглашениями о конфиденциальности
        
        5. ВАШИ ПРАВА НА КОНФИДЕНЦИАЛЬНОСТЬ
        
        5.1 Доступ и контроль
        • Просмотр ваших сохраненных данных через настройки Приложения
        • Обновление или исправление вашей информации
        • Удаление вашего аккаунта и связанных данных
        
        5.2 Переносимость данных
        • Экспорт ваших игровых данных и статистики
        • Перенос ваших данных на другое устройство
        
        5.3 Права отказа
        • Отключение сбора аналитических данных
        • Отключение отчетов о сбоях
        • Управление настройками уведомлений
        
        6. КОНФИДЕНЦИАЛЬНОСТЬ ДЕТЕЙ
        
        6.1 Возрастные ограничения
        • Наше Приложение подходит для пользователей всех возрастов
        • Мы сознательно не собираем личную информацию от детей младше 13 лет
        • Родители могут связаться с нами для запроса удаления данных своего ребенка
        
        6.2 Родительский контроль
        • Родители могут контролировать использование Приложения их ребенком
        • Нет внутриигровых покупок или социальных функций, которые могли бы подвергнуть детей риску
        
        7. МЕЖДУНАРОДНЫЕ ПЕРЕДАЧИ ДАННЫХ
        
        7.1 Глобальный сервис
        • Наше Приложение доступно по всему миру
        • Данные могут передаваться в страны с различными законами о конфиденциальности
        • Мы обеспечиваем соответствующие меры защиты
        
        8. COOKIES И ОТСЛЕЖИВАНИЕ
        
        8.1 Ограниченное использование
        • Мы не используем cookies для веб-отслеживания
        • Локальное хранилище используется только для игровой функциональности
        • Нет сторонней рекламы или пикселей отслеживания
        
        9. ИЗМЕНЕНИЯ В ДАННОЙ ПОЛИТИКЕ КОНФИДЕНЦИАЛЬНОСТИ
        
        9.1 Обновления
        • Мы можем время от времени обновлять эту политику
        • Существенные изменения будут сообщены через Приложение
        • Продолжение использования означает принятие изменений
        
        10. СВЯЖИТЕСЬ С НАМИ
        
        Если у вас есть вопросы об этой Политике конфиденциальности или наших практиках конфиденциальности:
        
        Email: privacy@worldarena.games
        Тема: Запрос по Политике конфиденциальности
        
        Мы ответим на ваш запрос в течение 30 дней.
        
        11. ДАТА ВСТУПЛЕНИЯ В СИЛУ
        
        Данная Политика конфиденциальности вступает в силу с даты, указанной в верхней части данного документа.
        
        Используя World Arena Flags, вы подтверждаете, что прочитали и поняли данную Политику конфиденциальности и соглашаетесь на сбор, использование и защиту вашей информации, как описано в данном документе.
        """
    }
    
    private var spanishPrivacy: String {
        """
        POLÍTICA DE PRIVACIDAD
        
        Última actualización: \(getCurrentDate())
        
        World Arena Games ("nosotros", "nuestro" o "nos") respeta tu privacidad y se compromete a proteger tu información personal. Esta Política de Privacidad explica cómo recopilamos, usamos y protegemos tu información cuando usas la aplicación móvil World Arena Flags ("Aplicación").
        
        1. INFORMACIÓN QUE RECOPILAMOS
        
        1.1 Información que proporcionas
        • Información de cuenta (si eliges crear una cuenta)
        • Preferencias y configuraciones del juego
        • Comentarios y comunicaciones que nos envías
        
        1.2 Información recopilada automáticamente
        • Estadísticas del juego y datos de progreso
        • Información del dispositivo (tipo de dispositivo, versión del sistema operativo)
        • Análisis de uso (sesiones de juego, características utilizadas)
        • Informes de errores y registros de errores
        
        1.3 Información que NO recopilamos
        • No recopilamos tu nombre real, dirección de correo electrónico o número de teléfono a menos que lo proporciones voluntariamente
        • No accedemos a tus contactos, fotos u otros archivos personales
        • No rastreamos tu ubicación
        
        2. CÓMO USAMOS TU INFORMACIÓN
        
        2.1 Para proporcionar y mejorar nuestro servicio
        • Entregar funcionalidad y características del juego
        • Guardar tu progreso del juego y preferencias
        • Analizar patrones de uso para mejorar la Aplicación
        • Corregir errores y problemas técnicos
        
        2.2 Para comunicarnos contigo
        • Responder a tus consultas y solicitudes de soporte
        • Enviar actualizaciones importantes sobre la Aplicación
        • Proporcionar atención al cliente
        
        2.3 Para análisis e investigación
        • Entender cómo los usuarios interactúan con la Aplicación
        • Mejorar el diseño del juego y la experiencia del usuario
        • Desarrollar nuevas características y contenido
        
        3. CÓMO ALMACENAMOS Y PROTEGEMOS TU INFORMACIÓN
        
        3.1 Almacenamiento de datos
        • La mayoría de tus datos se almacenan localmente en tu dispositivo
        • Algunos datos pueden almacenarse en servidores seguros en la nube para fines de respaldo
        • Usamos cifrado estándar de la industria para proteger tus datos
        
        3.2 Seguridad de datos
        • Implementamos medidas técnicas y organizativas apropiadas
        • Evaluaciones de seguridad y actualizaciones regulares
        • Acceso limitado a información personal solo por personal autorizado
        
        3.3 Retención de datos
        • Retenemos tu información solo el tiempo necesario
        • Puedes eliminar tus datos en cualquier momento a través de la configuración de la Aplicación
        • Las cuentas inactivas pueden eliminarse automáticamente después de períodos prolongados
        
        4. COMPARTIR TU INFORMACIÓN
        
        4.1 No vendemos tu información
        • Nunca vendemos, alquilamos o intercambiamos tu información personal
        • Tu privacidad no es una mercancía para nosotros
        
        4.2 Compartir limitado
        Podemos compartir tu información solo en estas circunstancias:
        • Con tu consentimiento explícito
        • Para cumplir con obligaciones legales
        • Para proteger nuestros derechos y la seguridad de nuestros usuarios
        • En conexión con una transferencia de negocio (fusión, adquisición)
        
        4.3 Servicios de terceros
        • Podemos usar servicios de análisis de terceros (solo datos anonimizados)
        • Proveedores de almacenamiento en la nube para respaldo de datos (cifrado)
        • Estos servicios están sujetos a estrictos acuerdos de privacidad
        
        5. TUS DERECHOS DE PRIVACIDAD
        
        5.1 Acceso y control
        • Ver tus datos almacenados a través de la configuración de la Aplicación
        • Actualizar o corregir tu información
        • Eliminar tu cuenta y datos asociados
        
        5.2 Portabilidad de datos
        • Exportar tus datos del juego y estadísticas
        • Transferir tus datos a otro dispositivo
        
        5.3 Derechos de exclusión
        • Deshabilitar la recopilación de datos de análisis
        • Desactivar informes de errores
        • Gestionar preferencias de notificación
        
        6. PRIVACIDAD DE NIÑOS
        
        6.1 Restricciones de edad
        • Nuestra Aplicación es adecuada para usuarios de todas las edades
        • No recopilamos conscientemente información personal de niños menores de 13 años
        • Los padres pueden contactarnos para solicitar la eliminación de los datos de su hijo
        
        6.2 Controles parentales
        • Los padres pueden monitorear y controlar el uso de la Aplicación por parte de su hijo
        • No hay compras dentro de la aplicación o características sociales que puedan exponer a los niños
        
        7. TRANSFERENCIAS INTERNACIONALES DE DATOS
        
        7.1 Servicio global
        • Nuestra Aplicación está disponible en todo el mundo
        • Los datos pueden transferirse a países con diferentes leyes de privacidad
        • Aseguramos que se implementen las salvaguardias apropiadas
        
        8. COOKIES Y SEGUIMIENTO
        
        8.1 Uso limitado
        • No usamos cookies para seguimiento web
        • El almacenamiento local se usa solo para funcionalidad del juego
        • No hay publicidad de terceros o píxeles de seguimiento
        
        9. CAMBIOS A ESTA POLÍTICA DE PRIVACIDAD
        
        9.1 Actualizaciones
        • Podemos actualizar esta política de vez en cuando
        • Los cambios materiales se comunicarán a través de la Aplicación
        • El uso continuo constituye aceptación de los cambios
        
        10. CONTÁCTANOS
        
        Si tienes preguntas sobre esta Política de Privacidad o nuestras prácticas de privacidad:
        
        Email: privacy@worldarena.games
        Asunto: Consulta sobre Política de Privacidad
        
        Responderemos a tu consulta dentro de 30 días.
        
        11. FECHA EFECTIVA
        
        Esta Política de Privacidad es efectiva a partir de la fecha listada en la parte superior de este documento.
        
        Al usar World Arena Flags, reconoces que has leído y entendido esta Política de Privacidad y aceptas nuestra recopilación, uso y protección de tu información como se describe aquí.
        """
    }
    
    private var ukrainianPrivacy: String {
        """
        ПОЛІТИКА КОНФІДЕНЦІЙНОСТІ
        
        Останнє оновлення: \(getCurrentDate())
        
        World Arena Games ("ми", "наш" або "нас") поважає вашу конфіденційність і зобов'язується захищати вашу особисту інформацію. Ця Політика конфіденційності пояснює, як ми збираємо, використовуємо та захищаємо вашу інформацію при використанні мобільного додатку World Arena Flags ("Додаток").
        
        1. ІНФОРМАЦІЯ, ЯКУ МИ ЗБИРАЄМО
        
        1.1 Інформація, яку ви надаєте
        • Інформація про обліковий запис (якщо ви вирішите створити обліковий запис)
        • Ігрові переваги та налаштування
        • Відгуки та повідомлення, які ви нам надсилаєте
        
        1.2 Автоматично зібрана інформація
        • Ігрова статистика та дані про прогрес
        • Інформація про пристрій (тип пристрою, версія операційної системи)
        • Аналітика використання (ігрові сесії, використовувані функції)
        • Звіти про збої та журнали помилок
        
        1.3 Інформація, яку ми НЕ збираємо
        • Ми не збираємо ваше справжнє ім'я, адресу електронної пошти або номер телефону, якщо ви добровільно не надасте їх
        • Ми не отримуємо доступ до ваших контактів, фотографій або інших особистих файлів
        • Ми не відстежуємо ваше місцезнаходження
        
        2. ЯК МИ ВИКОРИСТОВУЄМО ВАШУ ІНФОРМАЦІЮ
        
        2.1 Для надання та покращення нашого сервісу
        • Забезпечення ігрової функціональності та можливостей
        • Збереження вашого ігрового прогресу та переваг
        • Аналіз патернів використання для покращення Додатку
        • Виправлення помилок та технічних проблем
        
        2.2 Для спілкування з вами
        • Відповіді на ваші запити та звернення до служби підтримки
        • Надсилання важливих оновлень про Додаток
        • Надання клієнтської підтримки
        
        2.3 Для аналітики та досліджень
        • Розуміння того, як користувачі взаємодіють з Додатком
        • Покращення дизайну гри та користувацького досвіду
        • Розробка нових функцій та контенту
        
        3. ЯК МИ ЗБЕРІГАЄМО ТА ЗАХИЩАЄМО ВАШУ ІНФОРМАЦІЮ
        
        3.1 Зберігання даних
        • Більшість ваших даних зберігається локально на вашому пристрої
        • Деякі дані можуть зберігатися на захищених хмарних серверах для резервного копіювання
        • Ми використовуємо стандартне шифрування для захисту ваших даних
        
        3.2 Безпека даних
        • Ми застосовуємо відповідні технічні та організаційні заходи
        • Регулярні оцінки безпеки та оновлення
        • Обмежений доступ до особистої інформації лише авторизованому персоналу
        
        3.3 Зберігання даних
        • Ми зберігаємо вашу інформацію лише стільки, скільки необхідно
        • Ви можете видалити свої дані в будь-який час через налаштування Додатку
        • Неактивні облікові записи можуть бути автоматично видалені після тривалих періодів
        
        4. ПЕРЕДАЧА ВАШОЇ ІНФОРМАЦІЇ
        
        4.1 Ми не продаємо вашу інформацію
        • Ми ніколи не продаємо, не здаємо в оренду і не торгуємо вашою особистою інформацією
        • Ваша конфіденційність для нас не товар
        
        4.2 Обмежена передача
        Ми можемо передавати вашу інформацію лише в таких обставинах:
        • З вашої явної згоди
        • Для дотримання правових зобов'язань
        • Для захисту наших прав та безпеки наших користувачів
        • У зв'язку з передачею бізнесу (злиття, поглинання)
        
        4.3 Сторонні сервіси
        • Ми можемо використовувати сторонні аналітичні сервіси (лише анонімізовані дані)
        • Провайдери хмарного зберігання для резервного копіювання даних (зашифровані)
        • Ці сервіси пов'язані суворими угодами про конфіденційність
        
        5. ВАШІ ПРАВА НА КОНФІДЕНЦІЙНІСТЬ
        
        5.1 Доступ та контроль
        • Перегляд ваших збережених даних через налаштування Додатку
        • Оновлення або виправлення вашої інформації
        • Видалення вашого облікового запису та пов'язаних даних
        
        5.2 Переносимість даних
        • Експорт ваших ігрових даних та статистики
        • Перенесення ваших даних на інший пристрій
        
        5.3 Права відмови
        • Відключення збору аналітичних даних
        • Відключення звітів про збої
        • Керування налаштуваннями сповіщень
        
        6. КОНФІДЕНЦІЙНІСТЬ ДІТЕЙ
        
        6.1 Вікові обмеження
        • Наш Додаток підходить для користувачів усіх віків
        • Ми свідомо не збираємо особисту інформацію від дітей молодше 13 років
        • Батьки можуть зв'язатися з нами для запиту видалення даних своєї дитини
        
        6.2 Батьківський контроль
        • Батьки можуть контролювати використання Додатку їхньою дитиною
        • Немає внутрішньоігрових покупок або соціальних функцій, які могли б піддати дітей ризику
        
        7. МІЖНАРОДНІ ПЕРЕДАЧІ ДАНИХ
        
        7.1 Глобальний сервіс
        • Наш Додаток доступний по всьому світу
        • Дані можуть передаватися в країни з різними законами про конфіденційність
        • Ми забезпечуємо відповідні заходи захисту
        
        8. COOKIES ТА ВІДСТЕЖЕННЯ
        
        8.1 Обмежене використання
        • Ми не використовуємо cookies для веб-відстеження
        • Локальне сховище використовується лише для ігрової функціональності
        • Немає сторонньої реклами або пікселів відстеження
        
        9. ЗМІНИ В ЦІЙ ПОЛІТИЦІ КОНФІДЕНЦІЙНОСТІ
        
        9.1 Оновлення
        • Ми можемо час від часу оновлювати цю політику
        • Суттєві зміни будуть повідомлені через Додаток
        • Продовження використання означає прийняття змін
        
        10. ЗВ'ЯЖІТЬСЯ З НАМИ
        
        Якщо у вас є питання щодо цієї Політики конфіденційності або наших практик конфіденційності:
        
        Email: privacy@worldarena.games
        Тема: Запит щодо Політики конфіденційності
        
        Ми відповімо на ваш запит протягом 30 днів.
        
        11. ДАТА НАБРАННЯ ЧИННОСТІ
        
        Ця Політика конфіденційності набирає чинності з дати, зазначеної у верхній частині цього документа.
        
        Використовуючи World Arena Flags, ви підтверджуєте, що прочитали та зрозуміли цю Політику конфіденційності та погоджуєтеся на збір, використання та захист вашої інформації, як описано в цьому документі.
        """
    }
    
    private var catalanPrivacy: String {
        """
        POLÍTICA DE PRIVACITAT
        
        Última actualització: \(getCurrentDate())
        
        World Arena Games ("nosaltres", "nostre" o "ens") respecta la teva privacitat i es compromet a protegir la teva informació personal. Aquesta Política de Privacitat explica com recopilem, utilitzem i protegim la teva informació quan utilitzes l'aplicació mòbil World Arena Flags ("Aplicació").
        
        1. INFORMACIÓ QUE RECOPILEM
        
        1.1 Informació que proporciones
        • Informació del compte (si tries crear un compte)
        • Preferències i configuracions del joc
        • Comentaris i comunicacions que ens envies
        
        1.2 Informació recopilada automàticament
        • Estadístiques del joc i dades de progrés
        • Informació del dispositiu (tipus de dispositiu, versió del sistema operatiu)
        • Anàlisi d'ús (sessions de joc, característiques utilitzades)
        • Informes d'errors i registres d'errors
        
        1.3 Informació que NO recopilem
        • No recopilem el teu nom real, adreça de correu electrònic o número de telèfon a menys que el proporcionis voluntàriament
        • No accedim als teus contactes, fotos o altres fitxers personals
        • No rastregem la teva ubicació
        
        2. COM UTILITZEM LA TEVA INFORMACIÓ
        
        2.1 Per proporcionar i millorar el nostre servei
        • Lliurar funcionalitat i característiques del joc
        • Desar el teu progrés del joc i preferències
        • Analitzar patrons d'ús per millorar l'Aplicació
        • Corregir errors i problemes tècnics
        
        2.2 Per comunicar-nos amb tu
        • Respondre a les teves consultes i sol·licituds de suport
        • Enviar actualitzacions importants sobre l'Aplicació
        • Proporcionar atenció al client
        
        2.3 Per a anàlisi i investigació
        • Entendre com els usuaris interactuen amb l'Aplicació
        • Millorar el disseny del joc i l'experiència de l'usuari
        • Desenvolupar noves característiques i contingut
        
        3. COM EMMAGATZEMEM I PROTEGIM LA TEVA INFORMACIÓ
        
        3.1 Emmagatzematge de dades
        • La majoria de les teves dades s'emmagatzemen localment al teu dispositiu
        • Algunes dades poden emmagatzemar-se en servidors segurs al núvol per a fins de còpia de seguretat
        • Utilitzem xifratge estàndard de la indústria per protegir les teves dades
        
        3.2 Seguretat de dades
        • Implementem mesures tècniques i organitzatives apropiades
        • Avaluacions de seguretat i actualitzacions regulars
        • Accés limitat a informació personal només per personal autoritzat
        
        3.3 Retenció de dades
        • Retem la teva informació només el temps necessari
        • Pots eliminar les teves dades en qualsevol moment a través de la configuració de l'Aplicació
        • Els comptes inactius poden eliminar-se automàticament després de períodes prolongats
        
        4. COMPARTIR LA TEVA INFORMACIÓ
        
        4.1 No venem la teva informació
        • Mai venem, lloguem o intercanviem la teva informació personal
        • La teva privacitat no és una mercaderia per a nosaltres
        
        4.2 Compartir limitat
        Podem compartir la teva informació només en aquestes circumstàncies:
        • Amb el teu consentiment explícit
        • Per complir amb obligacions legals
        • Per protegir els nostres drets i la seguretat dels nostres usuaris
        • En connexió amb una transferència de negoci (fusió, adquisició)
        
        4.3 Serveis de tercers
        • Podem utilitzar serveis d'anàlisi de tercers (només dades anonimitzades)
        • Proveïdors d'emmagatzematge al núvol per a còpia de seguretat de dades (xifrat)
        • Aquests serveis estan subjectes a estrictes acords de privacitat
        
        5. ELS TEUS DRETS DE PRIVACITAT
        
        5.1 Accés i control
        • Veure les teves dades emmagatzemades a través de la configuració de l'Aplicació
        • Actualitzar o corregir la teva informació
        • Eliminar el teu compte i dades associades
        
        5.2 Portabilitat de dades
        • Exportar les teves dades del joc i estadístiques
        • Transferir les teves dades a un altre dispositiu
        
        5.3 Drets d'exclusió
        • Deshabilitar la recopilació de dades d'anàlisi
        • Desactivar informes d'errors
        • Gestionar preferències de notificació
        
        6. PRIVACITAT DE NENS
        
        6.1 Restriccions d'edat
        • La nostra Aplicació és adequada per a usuaris de totes les edats
        • No recopilem conscientment informació personal de nens menors de 13 anys
        • Els pares poden contactar-nos per sol·licitar l'eliminació de les dades del seu fill
        
        6.2 Controls parentals
        • Els pares poden monitoritzar i controlar l'ús de l'Aplicació per part del seu fill
        • No hi ha compres dins de l'aplicació o característiques socials que puguin exposar els nens
        
        7. TRANSFERÈNCIES INTERNACIONALS DE DADES
        
        7.1 Servei global
        • La nostra Aplicació està disponible arreu del món
        • Les dades poden transferir-se a països amb diferents lleis de privacitat
        • Assegurem que s'implementin les salvaguardes apropiades
        
        8. COOKIES I SEGUIMENT
        
        8.1 Ús limitat
        • No utilitzem cookies per a seguiment web
        • L'emmagatzematge local s'utilitza només per a funcionalitat del joc
        • No hi ha publicitat de tercers o píxels de seguiment
        
        9. CANVIS A AQUESTA POLÍTICA DE PRIVACITAT
        
        9.1 Actualitzacions
        • Podem actualitzar aquesta política de tant en tant
        • Els canvis materials es comunicaran a través de l'Aplicació
        • L'ús continuat constitueix acceptació dels canvis
        
        10. CONTACTA'NS
        
        Si tens preguntes sobre aquesta Política de Privacitat o les nostres pràctiques de privacitat:
        
        Email: privacy@worldarena.games
        Assumpte: Consulta sobre Política de Privacitat
        
        Respondrem a la teva consulta dins de 30 dies.
        
        11. DATA EFECTIVA
        
        Aquesta Política de Privacitat és efectiva a partir de la data llistada a la part superior d'aquest document.
        
        En utilitzar World Arena Flags, reconeix que has llegit i entès aquesta Política de Privacitat i acceptes la nostra recopilació, ús i protecció de la teva informació com es descriu aquí.
        """
    }
    
    private var chinesePrivacy: String {
        """
        隐私政策
        
        最后更新：\(getCurrentDate())
        
        World Arena Games（"我们"、"我们的"或"我们"）尊重您的隐私并致力于保护您的个人信息。本隐私政策解释了当您使用World Arena Flags移动应用程序（"应用程序"）时，我们如何收集、使用和保护您的信息。
        
        1. 我们收集的信息
        
        1.1 您提供的信息
        • 账户信息（如果您选择创建账户）
        • 游戏偏好和设置
        • 您发送给我们的反馈和通信
        
        1.2 自动收集的信息
        • 游戏统计数据和进度数据
        • 设备信息（设备类型、操作系统版本）
        • 使用分析（游戏会话、使用的功能）
        • 崩溃报告和错误日志
        
        1.3 我们不收集的信息
        • 除非您自愿提供，我们不收集您的真实姓名、电子邮件地址或电话号码
        • 我们不访问您的联系人、照片或其他个人文件
        • 我们不跟踪您的位置
        
        2. 我们如何使用您的信息
        
        2.1 提供和改进我们的服务
        • 提供游戏功能和特性
        • 保存您的游戏进度和偏好
        • 分析使用模式以改进应用程序
        • 修复错误和技术问题
        
        2.2 与您沟通
        • 回应您的询问和支持请求
        • 发送关于应用程序的重要更新
        • 提供客户支持
        
        2.3 分析和研究
        • 了解用户如何与应用程序交互
        • 改进游戏设计和用户体验
        • 开发新功能和内容
        
        3. 我们如何存储和保护您的信息
        
        3.1 数据存储
        • 您的大部分数据存储在您的设备本地
        • 一些数据可能存储在安全的云服务器上用于备份目的
        • 我们使用行业标准加密来保护您的数据
        
        3.2 数据安全
        • 我们实施适当的技术和组织措施
        • 定期安全评估和更新
        • 仅限授权人员访问个人信息
        
        3.3 数据保留
        • 我们仅在必要时保留您的信息
        • 您可以随时通过应用程序设置删除您的数据
        • 非活跃账户可能在延长期后自动删除
        
        4. 共享您的信息
        
        4.1 我们不出售您的信息
        • 我们从不出售、出租或交易您的个人信息
        • 您的隐私对我们来说不是商品
        
        4.2 有限共享
        我们只在以下情况下可能共享您的信息：
        • 获得您的明确同意
        • 遵守法律义务
        • 保护我们的权利和用户的安全
        • 与业务转让相关（合并、收购）
        
        4.3 第三方服务
        • 我们可能使用第三方分析服务（仅匿名数据）
        • 云存储提供商用于数据备份（加密）
        • 这些服务受严格的隐私协议约束
        
        5. 您的隐私权利
        
        5.1 访问和控制
        • 通过应用程序设置查看您的存储数据
        • 更新或更正您的信息
        • 删除您的账户和相关数据
        
        5.2 数据可移植性
        • 导出您的游戏数据和统计信息
        • 将您的数据转移到另一个设备
        
        5.3 选择退出权利
        • 禁用分析数据收集
        • 关闭崩溃报告
        • 管理通知偏好
        
        6. 儿童隐私
        
        6.1 年龄限制
        • 我们的应用程序适合所有年龄段的用户
        • 我们不会故意收集13岁以下儿童的个人信息
        • 家长可以联系我们请求删除其孩子的数据
        
        6.2 家长控制
        • 家长可以监控和控制其孩子使用应用程序
        • 没有应用内购买或可能使儿童暴露的社交功能
        
        7. 国际数据传输
        
        7.1 全球服务
        • 我们的应用程序在全球范围内可用
        • 数据可能传输到具有不同隐私法律的国家
        • 我们确保实施适当的保障措施
        
        8. COOKIES和跟踪
        
        8.1 有限使用
        • 我们不使用cookies进行网络跟踪
        • 本地存储仅用于游戏功能
        • 没有第三方广告或跟踪像素
        
        9. 本隐私政策的更改
        
        9.1 更新
        • 我们可能会不时更新此政策
        • 重大更改将通过应用程序通知
        • 继续使用构成对更改的接受
        
        10. 联系我们
        
        如果您对此隐私政策或我们的隐私做法有疑问：
        
        电子邮件：privacy@worldarena.games
        主题：隐私政策咨询
        
        我们将在30天内回复您的询问。
        
        11. 生效日期
        
        本隐私政策自本文档顶部列出的日期起生效。
        
        通过使用World Arena Flags，您确认已阅读并理解本隐私政策，并同意我们按照此处描述的方式收集、使用和保护您的信息。
        """
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale.current
        return formatter.string(from: Date())
    }
}

#Preview {
    PrivacyPolicyView()
        .environmentObject(UserProfile.shared)
}
