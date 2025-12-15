from PIL import Image
import os

def remove_background(input_path, output_path, tolerance=30):
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        datas = img.getdata()
        
        # Get background color from top-left pixel
        bg_color = datas[0]
        
        newData = []
        for item in datas:
            # Check if pixel is close to background color
            if all(abs(item[i] - bg_color[i]) < tolerance for i in range(3)):
                newData.append((255, 255, 255, 0)) # Transparent
            else:
                newData.append(item)
        
        img.putdata(newData)
        img.save(output_path, "PNG")
        print(f"Successfully saved transparent logo to {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_file = r"c:\Users\conta\OneDrive\Documentos\RHEMA\mobile\assets\images\logo.png"
    output_file = r"c:\Users\conta\OneDrive\Documentos\RHEMA\mobile\assets\images\logo_transparent.png"
    
    if os.path.exists(input_file):
        remove_background(input_file, output_file)
    else:
        print(f"File not found: {input_file}")
