Примеры рисования на Факторе. Запускать любой пример так:
1. скачиваем папку с примером (допустим, rotation)
2. кладём эту папку в factor/work
3. запускаем factor.exe
4. вводим команды (вместо rotation название примера)
  
    USE: rotation  
    "rotation" run
    
Примеры с текстурами (texture, cube, sphere) работают под Windows. Если у вас Linux или MacOS,
замените images.loader.gdiplus в начале примера (в длинном списке после USING:) на
images.loader.gtk (для Linux) или
images.loader.cocoa (для MacOS)
