widget ProductPage {
  state quantity = 1;
  state isFavorite = false;
  state currentImage = 0;
  state images = [
    "https://via.placeholder.com/400x300/FF0000/FFFFFF?text=Product+A",
    "https://via.placeholder.com/400x300/00FF00/FFFFFF?text=Product+B",
    "https://via.placeholder.com/400x300/0000FF/FFFFFF?text=Product+C"
  ];

  fn toggleFavorite() {
    isFavorite = !isFavorite;
    if (isFavorite) {
      showToast("已加入收藏 ❤️");
    } else {
      showToast("已取消收藏");
    }
  }

  fn addToCart() {
    showToast("已加入購物車: " + toString(quantity) + " 件");
  }

  fn changeImage(index) {
    currentImage = index;
  }

  build {
    Column(
      crossAxisAlignment: "start",
      children: [
        // Image Carousel
        Stack(
          children: [
             Image(
                src: images[currentImage], 
                height: 250.0, 
                width: "infinity",
                fit: "cover"
             ),
             Positioned(
               bottom: 10.0,
               right: 10.0,
               child: Container(
                 padding: 8.0,
                 color: "black54",
                 child: Text(text: (currentImage + 1) + "/" + len(images), style: {"color": "white"})
               )
             )
          ]
        ),
        
        // Thumbnails
        SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: "center",
          children: [
            Button(text: "圖1", onPressed: fn() { changeImage(0); }),
            SizedBox(width: 8.0),
            Button(text: "圖2", onPressed: fn() { changeImage(1); }),
            SizedBox(width: 8.0),
            Button(text: "圖3", onPressed: fn() { changeImage(2); })
          ]
        ),

        Padding(
          padding: 16.0,
          child: Column(
            crossAxisAlignment: "start",
            children: [
              Row(
                mainAxisAlignment: "spaceBetween",
                children: [
                  Text(text: "Flux 限量版 T-Shirt", style: {"fontSize": 24.0, "fontWeight": "bold"}),
                  IconButton(
                    icon: isFavorite ? "favorite" : "favorite_border",
                    color: isFavorite ? "red" : "grey",
                    onPressed: fn() { toggleFavorite(); }
                  )
                ]
              ),
              
              Text(text: "$990", style: {"fontSize": 20.0, "color": "red", "fontWeight": "bold"}),
              SizedBox(height: 8.0),
              Text(text: "這是一件由 Flux 腳本語言動態渲染的 T-Shirt，支援熱更新與即時庫存查詢。", style: {"color": "grey"}),
              
              SizedBox(height: 24.0),
              
              // Quantity & Cart
              Row(
                children: [
                  Container(
                    decoration: {"border": "1px solid grey", "borderRadius": 4.0},
                    child: Row(
                      children: [
                        IconButton(icon: "remove", onPressed: fn() { if (quantity > 1) { quantity = quantity - 1; } }),
                        Text(text: toString(quantity), style: {"fontSize": 18.0, "fontWeight": "bold"}),
                        IconButton(icon: "add", onPressed: fn() { quantity = quantity + 1; })
                      ]
                    )
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Button(
                      text: "加入購物車", 
                      color: "blue",
                      textColor: "white",
                      onPressed: fn() { addToCart(); }
                    )
                  )
                ]
              )
            ]
          )
        )
      ]
    )
  }
}
