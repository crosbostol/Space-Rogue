shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float fuerza_refraccion : hint_range(0.0, 0.1) = 0.045; // Fuerza calibrada para refracción notable

void fragment() {
	// Usamos el canal alfa del dibujo para saber dónde hay una grieta
	if (COLOR.a > 0.01) {
		// Calcular desplazamiento real desviado del centro 0.5
		vec2 offset = (COLOR.rg - 0.5) * fuerza_refraccion;
		vec2 uv_distorsionada = SCREEN_UV + offset;
		
		// Leer el fondo distorsionado (estrellas, enemigos, proyectiles)
		vec4 color_fondo = texture(SCREEN_TEXTURE, uv_distorsionada);
		
		// Generar un destello blanco neón reflectivo puro tipo cristal (solo en el quiebre)
		// Multiplicamos el canal azul (COLOR.b) para generar un quiebre blanco neón brillante sobre la oscuridad
		vec4 brillo_cristal = vec4(1.0, 1.0, 1.0, 1.0) * COLOR.b * 0.7;
		
		// Inyectar el resultado final heredando el alfa para que los bordes se fundan de forma elástica
		COLOR = vec4((color_fondo + brillo_cristal).rgb, COLOR.a);
	} else {
		discard; // Si no hay línea, no procesamos nada para mantener los 144Hz libres
	}
}
