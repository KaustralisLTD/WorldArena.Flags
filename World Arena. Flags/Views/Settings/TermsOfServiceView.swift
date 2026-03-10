import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct TermsOfServiceView: View {
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
                    Text(getTermsContent())
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
        let languageCode = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        
        switch languageCode {
        case "ru": return "Условия использования"
        case "de": return "Nutzungsbedingungen"
        case "fr": return "Conditions d'utilisation"
        case "it": return "Termini di servizio"
        case "pt": return "Termos de Uso"
        case "pl": return "Warunki korzystania"
        case "nl": return "Gebruiksvoorwaarden"
        case "es": return "Términos de Servicio"
        case "uk": return "Умови використання"
        case "ca": return "Condicions de Servei"
        case "zh": return "服务条款"
        default: return "Terms of Service"
        }
    }
    
    private func getTermsContent() -> String {
        let languageCode = LocalizationManager.shared.currentLocale.languageCode ?? "en"
        
        switch languageCode {
        case "ru":
            return russianTerms
        case "es":
            return spanishTerms
        case "uk":
            return ukrainianTerms
        case "ca":
            return catalanTerms
        case "zh":
            return chineseTerms
        default:
            // Для новых языков, где юридический текст пока не переведен, используем английскую версию.
            return englishTerms
        }
    }
    
    private var englishTerms: String {
        """
        TERMS OF SERVICE
        
        Last updated: \(getCurrentDate())
        
        1. ACCEPTANCE OF TERMS
        
        By downloading, installing, or using World Arena Flags ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
        
        2. DESCRIPTION OF SERVICE
        
        World Arena Flags is a mobile educational game application that helps users learn and identify flags of countries around the world. The App provides various game modes, difficulty levels, and educational content related to world geography.
        
        3. USER ACCOUNTS AND DATA
        
        3.1 Account Creation: You may use the App without creating an account. If you choose to create an account, you must provide accurate information.
        
        3.2 Data Storage: Your game progress, statistics, and preferences are stored locally on your device and may be backed up to cloud services if enabled.
        
        3.3 User Responsibilities: You are responsible for maintaining the confidentiality of your account information and for all activities under your account.
        
        4. ACCEPTABLE USE
        
        4.1 You may use the App for personal, non-commercial purposes only.
        
        4.2 You agree not to:
        • Use the App for any illegal or unauthorized purpose
        • Attempt to reverse engineer or modify the App
        • Interfere with the App's functionality or security
        • Use automated tools to interact with the App
        
        5. INTELLECTUAL PROPERTY
        
        5.1 The App and its original content are owned by World Arena Games and are protected by copyright, trademark, and other laws.
        
        5.2 Flag images and country information are sourced from public domain or licensed sources.
        
        6. PRIVACY
        
        Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the App.
        
        7. DISCLAIMERS
        
        7.1 The App is provided "as is" without warranties of any kind.
        
        7.2 We do not guarantee that the App will be error-free or uninterrupted.
        
        7.3 Educational content is provided for informational purposes and may not be completely accurate or up-to-date.
        
        8. LIMITATION OF LIABILITY
        
        To the maximum extent permitted by law, World Arena Games shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.
        
        9. UPDATES AND MODIFICATIONS
        
        9.1 We may update the App from time to time to improve functionality and user experience.
        
        9.2 We reserve the right to modify these Terms at any time. Continued use of the App constitutes acceptance of modified Terms.
        
        10. TERMINATION
        
        We may terminate or suspend your access to the App at any time, with or without cause, with or without notice.
        
        11. GOVERNING LAW
        
        These Terms shall be governed by and construed in accordance with the laws of the jurisdiction where World Arena Games is located.
        
        12. CONTACT INFORMATION
        
        If you have any questions about these Terms, please contact us at:
        Email: legal@worldarena.games
        
        By using World Arena Flags, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
        """
    }
    
    private var russianTerms: String {
        """
        УСЛОВИЯ ИСПОЛЬЗОВАНИЯ
        
        Последнее обновление: \(getCurrentDate())
        
        1. ПРИНЯТИЕ УСЛОВИЙ
        
        Загружая, устанавливая или используя World Arena Flags ("Приложение"), вы соглашаетесь соблюдать настоящие Условия использования ("Условия"). Если вы не согласны с данными Условиями, не используйте Приложение.
        
        2. ОПИСАНИЕ СЕРВИСА
        
        World Arena Flags - это мобильное образовательное игровое приложение, которое помогает пользователям изучать и определять флаги стран мира. Приложение предоставляет различные игровые режимы, уровни сложности и образовательный контент, связанный с мировой географией.
        
        3. УЧЕТНЫЕ ЗАПИСИ И ДАННЫЕ ПОЛЬЗОВАТЕЛЕЙ
        
        3.1 Создание аккаунта: Вы можете использовать Приложение без создания аккаунта. Если вы решите создать аккаунт, вы должны предоставить точную информацию.
        
        3.2 Хранение данных: Ваш игровой прогресс, статистика и настройки хранятся локально на вашем устройстве и могут быть сохранены в облачных сервисах, если включена соответствующая функция.
        
        3.3 Обязанности пользователя: Вы несете ответственность за сохранение конфиденциальности информации вашего аккаунта и за все действия под вашим аккаунтом.
        
        4. ДОПУСТИМОЕ ИСПОЛЬЗОВАНИЕ
        
        4.1 Вы можете использовать Приложение только в личных, некоммерческих целях.
        
        4.2 Вы соглашаетесь не:
        • Использовать Приложение в незаконных или неавторизованных целях
        • Пытаться реверс-инжинирить или модифицировать Приложение
        • Вмешиваться в функциональность или безопасность Приложения
        • Использовать автоматизированные инструменты для взаимодействия с Приложением
        
        5. ИНТЕЛЛЕКТУАЛЬНАЯ СОБСТВЕННОСТЬ
        
        5.1 Приложение и его оригинальный контент принадлежат World Arena Games и защищены авторским правом, торговыми марками и другими законами.
        
        5.2 Изображения флагов и информация о странах получены из общедоступных или лицензированных источников.
        
        6. КОНФИДЕНЦИАЛЬНОСТЬ
        
        Ваша конфиденциальность важна для нас. Пожалуйста, ознакомьтесь с нашей Политикой конфиденциальности, которая также регулирует использование вами Приложения.
        
        7. ОТКАЗ ОТ ГАРАНТИЙ
        
        7.1 Приложение предоставляется "как есть" без каких-либо гарантий.
        
        7.2 Мы не гарантируем, что Приложение будет работать без ошибок или прерываний.
        
        7.3 Образовательный контент предоставляется в информационных целях и может быть не полностью точным или актуальным.
        
        8. ОГРАНИЧЕНИЕ ОТВЕТСТВЕННОСТИ
        
        В максимальной степени, разрешенной законом, World Arena Games не несет ответственности за любые косвенные, случайные, специальные, последующие или штрафные ущербы, возникающие в результате использования вами Приложения.
        
        9. ОБНОВЛЕНИЯ И ИЗМЕНЕНИЯ
        
        9.1 Мы можем время от времени обновлять Приложение для улучшения функциональности и пользовательского опыта.
        
        9.2 Мы оставляем за собой право изменять данные Условия в любое время. Продолжение использования Приложения означает принятие измененных Условий.
        
        10. ПРЕКРАЩЕНИЕ ДЕЙСТВИЯ
        
        Мы можем прекратить или приостановить ваш доступ к Приложению в любое время, с причиной или без причины, с уведомлением или без уведомления.
        
        11. ПРИМЕНИМОЕ ПРАВО
        
        Данные Условия регулируются и толкуются в соответствии с законодательством юрисдикции, где расположена World Arena Games.
        
        12. КОНТАКТНАЯ ИНФОРМАЦИЯ
        
        Если у вас есть вопросы по данным Условиям, свяжитесь с нами:
        Email: legal@worldarena.games
        
        Используя World Arena Flags, вы подтверждаете, что прочитали, поняли и соглашаетесь соблюдать данные Условия использования.
        """
    }
    
    private var spanishTerms: String {
        """
        TÉRMINOS DE SERVICIO
        
        Última actualización: \(getCurrentDate())
        
        1. ACEPTACIÓN DE TÉRMINOS
        
        Al descargar, instalar o usar World Arena Flags ("la Aplicación"), aceptas estar sujeto a estos Términos de Servicio ("Términos"). Si no estás de acuerdo con estos Términos, no uses la Aplicación.
        
        2. DESCRIPCIÓN DEL SERVICIO
        
        World Arena Flags es una aplicación móvil de juego educativo que ayuda a los usuarios a aprender e identificar banderas de países de todo el mundo. La Aplicación proporciona varios modos de juego, niveles de dificultad y contenido educativo relacionado con la geografía mundial.
        
        3. CUENTAS DE USUARIO Y DATOS
        
        3.1 Creación de cuenta: Puedes usar la Aplicación sin crear una cuenta. Si eliges crear una cuenta, debes proporcionar información precisa.
        
        3.2 Almacenamiento de datos: Tu progreso del juego, estadísticas y preferencias se almacenan localmente en tu dispositivo y pueden respaldarse en servicios en la nube si están habilitados.
        
        3.3 Responsabilidades del usuario: Eres responsable de mantener la confidencialidad de la información de tu cuenta y de todas las actividades bajo tu cuenta.
        
        4. USO ACEPTABLE
        
        4.1 Puedes usar la Aplicación solo para fines personales y no comerciales.
        
        4.2 Aceptas no:
        • Usar la Aplicación para cualquier propósito ilegal o no autorizado
        • Intentar hacer ingeniería inversa o modificar la Aplicación
        • Interferir con la funcionalidad o seguridad de la Aplicación
        • Usar herramientas automatizadas para interactuar con la Aplicación
        
        5. PROPIEDAD INTELECTUAL
        
        5.1 La Aplicación y su contenido original son propiedad de World Arena Games y están protegidos por derechos de autor, marcas registradas y otras leyes.
        
        5.2 Las imágenes de banderas e información de países provienen de fuentes de dominio público o con licencia.
        
        6. PRIVACIDAD
        
        Tu privacidad es importante para nosotros. Por favor, revisa nuestra Política de Privacidad, que también gobierna tu uso de la Aplicación.
        
        7. EXENCIONES DE RESPONSABILIDAD
        
        7.1 La Aplicación se proporciona "tal como está" sin garantías de ningún tipo.
        
        7.2 No garantizamos que la Aplicación esté libre de errores o ininterrumpida.
        
        7.3 El contenido educativo se proporciona con fines informativos y puede no ser completamente preciso o actualizado.
        
        8. LIMITACIÓN DE RESPONSABILIDAD
        
        En la máxima medida permitida por la ley, World Arena Games no será responsable de ningún daño indirecto, incidental, especial, consecuente o punitivo que surja de tu uso de la Aplicación.
        
        9. ACTUALIZACIONES Y MODIFICACIONES
        
        9.1 Podemos actualizar la Aplicación de vez en cuando para mejorar la funcionalidad y la experiencia del usuario.
        
        9.2 Nos reservamos el derecho de modificar estos Términos en cualquier momento. El uso continuado de la Aplicación constituye la aceptación de los Términos modificados.
        
        10. TERMINACIÓN
        
        Podemos terminar o suspender tu acceso a la Aplicación en cualquier momento, con o sin causa, con o sin aviso.
        
        11. LEY APLICABLE
        
        Estos Términos se regirán e interpretarán de acuerdo con las leyes de la jurisdicción donde se encuentra World Arena Games.
        
        12. INFORMACIÓN DE CONTACTO
        
        Si tienes alguna pregunta sobre estos Términos, contáctanos en:
        Email: legal@worldarena.games
        
        Al usar World Arena Flags, reconoces que has leído, entendido y aceptas estar sujeto a estos Términos de Servicio.
        """
    }
    
    private var ukrainianTerms: String {
        """
        УМОВИ ВИКОРИСТАННЯ
        
        Останнє оновлення: \(getCurrentDate())
        
        1. ПРИЙНЯТТЯ УМОВ
        
        Завантажуючи, встановлюючи або використовуючи World Arena Flags ("Додаток"), ви погоджуєтеся дотримуватися цих Умов використання ("Умови"). Якщо ви не погоджуєтеся з цими Умовами, не використовуйте Додаток.
        
        2. ОПИС СЕРВІСУ
        
        World Arena Flags - це мобільний освітній ігровий додаток, який допомагає користувачам вивчати та ідентифікувати прапори країн світу. Додаток надає різні ігрові режими, рівні складності та освітній контент, пов'язаний зі світовою географією.
        
        3. ОБЛІКОВІ ЗАПИСИ ТА ДАНІ КОРИСТУВАЧІВ
        
        3.1 Створення облікового запису: Ви можете використовувати Додаток без створення облікового запису. Якщо ви вирішите створити обліковий запис, ви повинні надати точну інформацію.
        
        3.2 Зберігання даних: Ваш ігровий прогрес, статистика та налаштування зберігаються локально на вашому пристрої та можуть бути збережені в хмарних сервісах, якщо увімкнено відповідну функцію.
        
        3.3 Обов'язки користувача: Ви несете відповідальність за збереження конфіденційності інформації вашого облікового запису та за всі дії під вашим обліковим записом.
        
        4. ДОПУСТИМІ ВИКОРИСТАННЯ
        
        4.1 Ви можете використовувати Додаток тільки в особистих, некомерційних цілях.
        
        4.2 Ви погоджуєтеся не:
        • Використовувати Додаток у незаконних або неавторизованих цілях
        • Намагатися зробити зворотну розробку або модифікувати Додаток
        • Втручатися у функціональність або безпеку Додатку
        • Використовувати автоматизовані інструменти для взаємодії з Додатком
        
        5. ІНТЕЛЕКТУАЛЬНА ВЛАСНІСТЬ
        
        5.1 Додаток та його оригінальний контент належать World Arena Games і захищені авторським правом, торговими марками та іншими законами.
        
        5.2 Зображення прапорів та інформація про країни отримані з загальнодоступних або ліцензованих джерел.
        
        6. КОНФІДЕНЦІЙНІСТЬ
        
        Ваша конфіденційність важлива для нас. Будь ласка, ознайомтеся з нашою Політикою конфіденційності, яка також регулює використання вами Додатку.
        
        7. ВІДМОВА ВІД ГАРАНТІЙ
        
        7.1 Додаток надається "як є" без будь-яких гарантій.
        
        7.2 Ми не гарантуємо, що Додаток буде працювати без помилок або переривань.
        
        7.3 Освітній контент надається в інформаційних цілях і може бути не повністю точним або актуальним.
        
        8. ОБМЕЖЕННЯ ВІДПОВІДАЛЬНОСТІ
        
        У максимальній мірі, дозволеній законом, World Arena Games не несе відповідальності за будь-які непрямі, випадкові, спеціальні, наступні або штрафні збитки, що виникають в результаті використання вами Додатку.
        
        9. ОНОВЛЕННЯ ТА ЗМІНИ
        
        9.1 Ми можемо час від часу оновлювати Додаток для покращення функціональності та користувацького досвіду.
        
        9.2 Ми залишаємо за собою право змінювати ці Умови в будь-який час. Продовження використання Додатку означає прийняття змінених Умов.
        
        10. ПРИПИНЕННЯ ДІЇ
        
        Ми можемо припинити або призупинити ваш доступ до Додатку в будь-який час, з причиною або без причини, з повідомленням або без повідомлення.
        
        11. ЗАСТОСОВНЕ ПРАВО
        
        Ці Умови регулюються та тлумачаться відповідно до законодавства юрисдикції, де розташована World Arena Games.
        
        12. КОНТАКТНА ІНФОРМАЦІЯ
        
        Якщо у вас є питання щодо цих Умов, зв'яжіться з нами:
        Email: legal@worldarena.games
        
        Використовуючи World Arena Flags, ви підтверджуєте, що прочитали, зрозуміли та погоджуєтеся дотримуватися цих Умов використання.
        """
    }
    
    private var catalanTerms: String {
        """
        CONDICIONS DE SERVEI
        
        Última actualització: \(getCurrentDate())
        
        1. ACCEPTACIÓ DE CONDICIONS
        
        En descarregar, instal·lar o utilitzar World Arena Flags ("l'Aplicació"), acceptes estar subjecte a aquestes Condicions de Servei ("Condicions"). Si no estàs d'acord amb aquestes Condicions, no facis servir l'Aplicació.
        
        2. DESCRIPCIÓ DEL SERVEI
        
        World Arena Flags és una aplicació mòbil de joc educatiu que ajuda els usuaris a aprendre i identificar banderes de països de tot el món. L'Aplicació proporciona diversos modes de joc, nivells de dificultat i contingut educatiu relacionat amb la geografia mundial.
        
        3. COMPTES D'USUARI I DADES
        
        3.1 Creació de compte: Pots utilitzar l'Aplicació sense crear un compte. Si tries crear un compte, has de proporcionar informació precisa.
        
        3.2 Emmagatzematge de dades: El teu progrés del joc, estadístiques i preferències s'emmagatzemen localment al teu dispositiu i poden fer-se còpia de seguretat als serveis al núvol si estan habilitats.
        
        3.3 Responsabilitats de l'usuari: Ets responsable de mantenir la confidencialitat de la informació del teu compte i de totes les activitats sota el teu compte.
        
        4. ÚS ACCEPTABLE
        
        4.1 Pots utilitzar l'Aplicació només per a fins personals i no comercials.
        
        4.2 Acceptes no:
        • Utilitzar l'Aplicació per a qualsevol propòsit il·legal o no autoritzat
        • Intentar fer enginyeria inversa o modificar l'Aplicació
        • Interferir amb la funcionalitat o seguretat de l'Aplicació
        • Utilitzar eines automatitzades per interactuar amb l'Aplicació
        
        5. PROPIETAT INTEL·LECTUAL
        
        5.1 L'Aplicació i el seu contingut original són propietat de World Arena Games i estan protegits per drets d'autor, marques registrades i altres lleis.
        
        5.2 Les imatges de banderes i informació de països provenen de fonts de domini públic o amb llicència.
        
        6. PRIVACITAT
        
        La teva privacitat és important per a nosaltres. Si us plau, revisa la nostra Política de Privacitat, que també governa el teu ús de l'Aplicació.
        
        7. EXENCIONS DE RESPONSABILITAT
        
        7.1 L'Aplicació es proporciona "tal com està" sense garanties de cap tipus.
        
        7.2 No garantim que l'Aplicació estigui lliure d'errors o ininterrompuda.
        
        7.3 El contingut educatiu es proporciona amb fins informatius i pot no ser completament precís o actualitzat.
        
        8. LIMITACIÓ DE RESPONSABILITAT
        
        En la màxima mesura permesa per la llei, World Arena Games no serà responsable de cap dany indirecte, incidental, especial, conseqüent o punitiu que sorgeixi del teu ús de l'Aplicació.
        
        9. ACTUALITZACIONS I MODIFICACIONS
        
        9.1 Podem actualitzar l'Aplicació de tant en tant per millorar la funcionalitat i l'experiència de l'usuari.
        
        9.2 Ens reservem el dret de modificar aquestes Condicions en qualsevol moment. L'ús continuat de l'Aplicació constitueix l'acceptació de les Condicions modificades.
        
        10. TERMINACIÓ
        
        Podem acabar o suspendre el teu accés a l'Aplicació en qualsevol moment, amb o sense causa, amb o sense avís.
        
        11. LLEI APLICABLE
        
        Aquestes Condicions es regiran i interpretaran d'acord amb les lleis de la jurisdicció on es troba World Arena Games.
        
        12. INFORMACIÓ DE CONTACTE
        
        Si tens alguna pregunta sobre aquestes Condicions, contacta'ns a:
        Email: legal@worldarena.games
        
        En utilitzar World Arena Flags, reconeix que has llegit, entès i acceptes estar subjecte a aquestes Condicions de Servei.
        """
    }
    
    private var chineseTerms: String {
        """
        服务条款
        
        最后更新：\(getCurrentDate())
        
        1. 条款接受
        
        通过下载、安装或使用World Arena Flags（"应用程序"），您同意受这些服务条款（"条款"）的约束。如果您不同意这些条款，请不要使用该应用程序。
        
        2. 服务描述
        
        World Arena Flags是一个移动教育游戏应用程序，帮助用户学习和识别世界各国的国旗。该应用程序提供各种游戏模式、难度级别和与世界地理相关的教育内容。
        
        3. 用户账户和数据
        
        3.1 账户创建：您可以在不创建账户的情况下使用该应用程序。如果您选择创建账户，您必须提供准确的信息。
        
        3.2 数据存储：您的游戏进度、统计数据和偏好设置存储在您的设备本地，如果启用，可能会备份到云服务。
        
        3.3 用户责任：您有责任维护账户信息的机密性以及账户下的所有活动。
        
        4. 可接受使用
        
        4.1 您只能将该应用程序用于个人、非商业目的。
        
        4.2 您同意不：
        • 将应用程序用于任何非法或未经授权的目的
        • 尝试对应用程序进行逆向工程或修改
        • 干扰应用程序的功能或安全性
        • 使用自动化工具与应用程序交互
        
        5. 知识产权
        
        5.1 该应用程序及其原始内容由World Arena Games拥有，受版权、商标和其他法律保护。
        
        5.2 国旗图像和国家信息来源于公共领域或许可来源。
        
        6. 隐私
        
        您的隐私对我们很重要。请查看我们的隐私政策，该政策也管理您对应用程序的使用。
        
        7. 免责声明
        
        7.1 该应用程序按"现状"提供，不提供任何形式的保证。
        
        7.2 我们不保证应用程序将无错误或不中断。
        
        7.3 教育内容仅供参考，可能不完全准确或最新。
        
        8. 责任限制
        
        在法律允许的最大范围内，World Arena Games不对因您使用应用程序而产生的任何间接、偶然、特殊、后果性或惩罚性损害承担责任。
        
        9. 更新和修改
        
        9.1 我们可能会不时更新应用程序以改善功能和用户体验。
        
        9.2 我们保留随时修改这些条款的权利。继续使用应用程序即表示接受修改后的条款。
        
        10. 终止
        
        我们可以随时终止或暂停您对应用程序的访问，无论是否有原因，无论是否通知。
        
        11. 管辖法律
        
        这些条款应受World Arena Games所在司法管辖区的法律管辖和解释。
        
        12. 联系信息
        
        如果您对这些条款有任何问题，请联系我们：
        电子邮件：legal@worldarena.games
        
        通过使用World Arena Flags，您确认已阅读、理解并同意受这些服务条款的约束。
        """
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = LocalizationManager.shared.currentLocale
        return formatter.string(from: Date())
    }
}

#Preview {
    TermsOfServiceView()
        .environmentObject(UserProfile.shared)
}
